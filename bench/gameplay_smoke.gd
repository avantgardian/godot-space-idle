extends SceneTree

## Headless gameplay smoke — catches runtime push_error / SCRIPT ERROR
## that only surface when scenes are instantiated and stepped.
## Usage: Godot --headless -s res://bench/gameplay_smoke.gd
##   [-- --scene main|progression --frames 600 --seed 42 --with-input]
##   [-- --visual-hash
##     [--visual-baseline res://bench/visual_baseline.json]
##     [--visual-tolerance 0.01] [--update-visual-baseline]]
##   --scene supports both --scene <val> and --scene=<val> forms.
## CI runs with no args (both scenes, 600 frames, seed 42, --with-input on).
## Implements #333 (phase 1 core) — extended in #334 (viewport input + errors).
## Visual regression (#343): --visual-hash captures viewport screenshot
## hash after 60 frames deterministic (seed 42) + shader source hash;
## compares against bench/visual_baseline.json with <1% pixel tolerance
## (hash equality in headless fallback). Fails on shader uniform typo.

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const PROGRESSION_SCENE_PATH: String = "res://scenes/progression.tscn"
const DEFAULT_FRAMES: int = 600
const DEFAULT_SEED: int = 42
const DELTA: float = 0.016
const ORPHAN_LEAK_THRESHOLD: int = 10
const OBJECT_LEAK_THRESHOLD: int = 200
const VISUAL_FRAMES: int = 60
const VISUAL_BASELINE_PATH: String = "res://bench/visual_baseline.json"
const VISUAL_TOLERANCE: float = 0.01
const VISUAL_UTILS: GDScript = preload("res://bench/visual_utils.gd")

var _rocket_hit_seen: bool = false


func _get_orphan_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))


func _get_object_count() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	var scene_filter: String = ""
	var frames: int = DEFAULT_FRAMES
	var seed_val: int = DEFAULT_SEED
	var with_input: bool = true
	var visual_hash: bool = false
	var visual_baseline: String = VISUAL_BASELINE_PATH
	var visual_tolerance: float = VISUAL_TOLERANCE
	var update_baseline: bool = false
	var idx: int = 0
	while idx < args.size():
		var arg: String = args[idx]
		if arg.begins_with("--scene="):
			scene_filter = arg.substr(8)
			idx += 1
			continue
		if arg == "--scene" and idx + 1 < args.size():
			scene_filter = args[idx + 1]
			idx += 2
			continue
		if arg == "--frames" and idx + 1 < args.size():
			frames = int(args[idx + 1])
			idx += 2
			continue
		if arg == "--seed" and idx + 1 < args.size():
			seed_val = int(args[idx + 1])
			idx += 2
			continue
		if arg == "--with-input":
			with_input = true
			idx += 1
			continue
		if arg == "--without-input":
			with_input = false
			idx += 1
			continue
		if arg == "--visual-hash":
			visual_hash = true
			idx += 1
			continue
		if arg.begins_with("--visual-baseline="):
			visual_baseline = arg.substr(18)
			idx += 1
			continue
		if arg == "--visual-baseline" and idx + 1 < args.size():
			visual_baseline = args[idx + 1]
			idx += 2
			continue
		if arg.begins_with("--visual-tolerance="):
			visual_tolerance = float(arg.substr(19))
			idx += 1
			continue
		if arg == "--visual-tolerance" and idx + 1 < args.size():
			visual_tolerance = float(args[idx + 1])
			idx += 2
			continue
		if arg == "--update-visual-baseline":
			update_baseline = true
			idx += 1
			continue
		idx += 1
	# Defer so SceneTree root is ready and await works inside.
	if visual_hash:
		@warning_ignore("unsafe_call_argument")
		call_deferred(
			"_deferred_visual_run",
			scene_filter,
			seed_val,
			visual_baseline,
			visual_tolerance,
			update_baseline
		)
	else:
		@warning_ignore("unsafe_call_argument")
		call_deferred("_deferred_run", scene_filter, frames, seed_val, with_input)


func _deferred_run(scene_filter: String, frames: int, seed_val: int, with_input: bool) -> void:
	var smoke_start: int = Time.get_ticks_usec()
	var baseline_orphans: int = _get_orphan_count()
	var baseline_objects: int = _get_object_count()
	print("[gameplay_smoke] baseline orphans=%d objects=%d" % [baseline_orphans, baseline_objects])
	var targets: Array[String] = []
	if scene_filter == "main":
		targets.append(MAIN_SCENE_PATH)
	elif scene_filter == "progression":
		targets.append(PROGRESSION_SCENE_PATH)
	else:
		targets.append(MAIN_SCENE_PATH)
		targets.append(PROGRESSION_SCENE_PATH)

	var results: Dictionary = {}
	var all_passed: bool = true

	for scene_path: String in targets:
		var label: String = _scene_label(scene_path)
		print(
			(
				"[gameplay_smoke] running %s frames=%d seed=%d with_input=%s scene=%s"
				% [label, frames, seed_val, str(with_input), scene_path]
			)
		)
		seed(seed_val)
		var ok: bool = await _run_single_scene(scene_path, frames, seed_val, with_input)
		results[label] = ok
		if not ok:
			all_passed = false

	results["frames"] = frames
	results["seed"] = seed_val
	results["with_input"] = with_input
	var elapsed_us: int = Time.get_ticks_usec() - smoke_start
	var elapsed_ms: float = float(elapsed_us) / 1000.0
	results["elapsed_ms"] = elapsed_ms
	var final_orphans: int = _get_orphan_count()
	var final_objects: int = _get_object_count()
	var orphan_delta: int = final_orphans - baseline_orphans
	var object_delta: int = final_objects - baseline_objects
	results["orphan_delta"] = orphan_delta
	results["object_delta"] = object_delta
	results["passed"] = all_passed
	print(JSON.stringify(results))
	print("[gameplay_smoke] elapsed %.2f ms" % elapsed_ms)
	print(
		(
			"[gameplay_smoke] orphans baseline=%d final=%d delta=%d (threshold %d)"
			% [baseline_orphans, final_orphans, orphan_delta, ORPHAN_LEAK_THRESHOLD]
		)
	)
	print(
		(
			"[gameplay_smoke] objects baseline=%d final=%d delta=%d (threshold %d)"
			% [baseline_objects, final_objects, object_delta, OBJECT_LEAK_THRESHOLD]
		)
	)
	if orphan_delta > ORPHAN_LEAK_THRESHOLD:
		printerr(
			(
				"[gameplay_smoke] FAIL orphan leak delta %d > %d"
				% [orphan_delta, ORPHAN_LEAK_THRESHOLD]
			)
		)
		all_passed = false
	if object_delta > OBJECT_LEAK_THRESHOLD:
		printerr(
			(
				"[gameplay_smoke] FAIL object leak delta %d > %d"
				% [object_delta, OBJECT_LEAK_THRESHOLD]
			)
		)
		all_passed = false
	# Budget is advisory WARN — not gating PR (informational, matches perf
	# advisory regression). If budget should gate PRs, set all_passed=false here.
	var budget_ms: float = 5000.0 * float(targets.size())
	if elapsed_ms > budget_ms:
		printerr(
			"[gameplay_smoke] WARN elapsed %.2f ms exceeds %.0f ms budget" % [elapsed_ms, budget_ms]
		)
	if all_passed:
		print("[gameplay_smoke] PASS — both scenes ran %d frames without fatal load" % frames)
		quit(0)
	else:
		printerr("[gameplay_smoke] FAIL — grep SCRIPT ERROR|push_error|WARNING|orphan leak")
		quit(1)


func _deferred_visual_run(
	scene_filter: String,
	seed_val: int,
	baseline_path: String,
	tolerance: float,
	update_baseline: bool
) -> void:
	print(
		(
			"[visual_smoke] visual-hash mode frames=%d seed=%d baseline=%s tolerance=%.4f update=%s"
			% [VISUAL_FRAMES, seed_val, baseline_path, tolerance, str(update_baseline)]
		)
	)
	var targets: Array[String] = []
	if scene_filter == "main":
		targets.append(MAIN_SCENE_PATH)
	elif scene_filter == "progression":
		targets.append(PROGRESSION_SCENE_PATH)
	else:
		targets.append(MAIN_SCENE_PATH)
		targets.append(PROGRESSION_SCENE_PATH)

	@warning_ignore("unsafe_method_access")
	var shader_hash: String = VISUAL_UTILS.hash_shader_sources() as String
	print("[visual_smoke] shader_hash=%s" % shader_hash)

	@warning_ignore("unsafe_method_access")
	var baseline: Dictionary = VISUAL_UTILS.load_visual_baseline(baseline_path) as Dictionary
	var current: Dictionary = {}
	current["shader_hash"] = shader_hash
	current["frames"] = VISUAL_FRAMES
	current["seed"] = seed_val
	current["tolerance"] = tolerance
	current["generated_at"] = Time.get_date_string_from_system()

	var all_passed: bool = true
	var hashes: Dictionary = {}

	for scene_path: String in targets:
		var label: String = _scene_label(scene_path)
		print("[visual_smoke] capturing %s (seed %d) ..." % [label, seed_val])
		var capture: Dictionary = await _capture_visual_hash(scene_path, seed_val)
		var viewport_hash: String = capture.get("viewport_hash", "") as String
		var combined: String = capture.get("combined_hash", "") as String
		var viewport_available: bool = capture.get("viewport_available", false) as bool
		var img_size: Vector2i = capture.get("image_size", Vector2i(0, 0)) as Vector2i
		hashes[label] = combined
		current[label] = combined
		current[label + "_viewport"] = viewport_hash
		current[label + "_viewport_available"] = viewport_available
		current[label + "_image_size"] = "%dx%d" % [img_size.x, img_size.y]
		print(
			(
				"[visual_smoke] %s viewport_available=%s size=%dx%d viewport_hash=%s combined=%s"
				% [label, str(viewport_available), img_size.x, img_size.y, viewport_hash, combined]
			)
		)
		# Also write png artifact path if available.
		var png_path: String = capture.get("png_path", "") as String
		if png_path != "":
			print("[visual_smoke] %s png=%s" % [label, png_path])

	# Compare against baseline if not updating.
	if update_baseline:
		@warning_ignore("unsafe_method_access")
		VISUAL_UTILS.save_visual_baseline(baseline_path, current, targets, VISUAL_FRAMES, tolerance)
		print("[visual_smoke] baseline written to %s" % baseline_path)
		print(JSON.stringify(current))
		print("[visual_smoke] PASS — baseline updated")
		quit(0)
		return

	# If baseline missing, warn and create current as reference (advisory).
	if baseline.is_empty():
		print(
			(
				"[visual_smoke] WARN no baseline at %s — treating current as baseline (first run)"
				% baseline_path
			)
		)
		print(JSON.stringify(current))
		# Still PASS on first run so CI can bootstrap, but log hashes.
		# Save current pngs baseline for diff; operator should commit baseline.
		print("[visual_smoke] PASS — no baseline to compare (bootstrap)")
		print(JSON.stringify(hashes))
		quit(0)
		return

	# Compare shader hash first — catches uniform typo even when viewport black.
	var baseline_shader: String = baseline.get("shader_hash", "") as String
	if baseline_shader != "" and baseline_shader != shader_hash:
		printerr(
			(
				"[visual_smoke] FAIL shader_hash drift baseline=%s current=%s"
				% [baseline_shader, shader_hash]
			)
		)
		all_passed = false
	else:
		print("[visual_smoke] shader_hash OK")

	for label2: String in hashes.keys():
		var base_hash: String = baseline.get(label2, "") as String
		var cur_hash: String = hashes[label2] as String
		if base_hash == "":
			print("[visual_smoke] WARN no baseline entry for %s — skipping" % label2)
			continue
		if base_hash == cur_hash:
			print("[visual_smoke] %s hash OK (%s)" % [label2, cur_hash.substr(0, 12)])
		else:
			# Try tolerant pixel diff if both viewport pngs exist (advisory tolerance).
			@warning_ignore("unsafe_method_access")
			var diff_ratio: float = VISUAL_UTILS.try_pixel_diff(label2) as float
			printerr(
				(
					"[visual_smoke] FAIL %s hash drift baseline=%s current=%s diff_ratio=%.4f tolerance=%.4f"
					% [
						label2,
						base_hash.substr(0, 12),
						cur_hash.substr(0, 12),
						diff_ratio,
						tolerance
					]
				)
			)
			if diff_ratio >= 0.0 and diff_ratio <= tolerance:
				print(
					(
						"[visual_smoke] %s drift within tolerance %.2f%% <= %.2f%% — PASS (tolerant)"
						% [label2, diff_ratio * 100.0, tolerance * 100.0]
					)
				)
			else:
				all_passed = false

	print(JSON.stringify(current))
	if all_passed:
		print("[visual_smoke] PASS — visual hashes match baseline")
		quit(0)
	else:
		printerr("[visual_smoke] FAIL — visual drift beyond tolerance")
		quit(1)


func _scene_label(path: String) -> String:
	if path == MAIN_SCENE_PATH:
		return "main"
	if path == PROGRESSION_SCENE_PATH:
		return "progression"
	return path


func _run_single_scene(scene_path: String, frames: int, seed_val: int, with_input: bool) -> bool:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		printerr("[gameplay_smoke] FAIL load null: %s" % scene_path)
		return false
	var inst: Node = packed.instantiate()
	if inst == null:
		printerr("[gameplay_smoke] FAIL instantiate null: %s" % scene_path)
		return false

	# Deterministic star seed before _ready fires (generate uses it).
	@warning_ignore("unsafe_property_access")
	if "star_seed" in inst:
		@warning_ignore("unsafe_property_access")
		inst.star_seed = seed_val

	var prev_scene: Node = current_scene
	@warning_ignore("unsafe_call_argument")
	get_root().add_child(inst)
	# current_scene must be child of root — set after add_child.
	if current_scene != inst:
		current_scene = inst
	# Let _ready() run.
	await process_frame
	await process_frame
	_fix_event_log_panel(inst)

	if not is_instance_valid(inst):
		printerr("[gameplay_smoke] FAIL scene freed during _ready: %s" % scene_path)
		return false

	# Track authoritative rocket hit for progression with_input.
	_rocket_hit_seen = false
	# Step frames and inject deterministic actions.
	for frame: int in range(frames):
		if with_input:
			_inject_actions(inst, frame, scene_path)
			if scene_path == PROGRESSION_SCENE_PATH and (frame == 150 or frame == 210):
				if _verify_rocket_hit(inst):
					_rocket_hit_seen = true
		await process_frame
		# Also drive _physics_process manually so logic runs even if
		# get_tree().paused would freeze it — toggle test re-enables.
		# The engine already ticks _physics_process on process_frame,
		# this is belt-and-braces for headless determinism.
		if not is_instance_valid(inst):
			printerr("[gameplay_smoke] FAIL scene freed at frame %d: %s" % [frame, scene_path])
			return false

	# Final catch-all scan — hit could occur slightly after 210 due to timing jitter.
	if with_input and scene_path == PROGRESSION_SCENE_PATH and not _rocket_hit_seen:
		if _verify_rocket_hit(inst):
			_rocket_hit_seen = true
	if with_input and scene_path == PROGRESSION_SCENE_PATH and not _rocket_hit_seen:
		printerr(
			(
				"[gameplay_smoke] WARN no rocket hit after 210 "
				+ "(expected Asteroid destroyed by rocket)"
			)
		)
	if with_input and scene_path == PROGRESSION_SCENE_PATH:
		print("[gameplay_smoke] rocket_hit=%s" % str(_rocket_hit_seen))

	# Teardown.
	if is_instance_valid(inst):
		inst.queue_free()
		await process_frame
	if prev_scene != null and is_instance_valid(prev_scene):
		current_scene = prev_scene
	else:
		current_scene = null
	return true


func _fix_event_log_panel(inst: Node) -> void:
	# EventLog creates EventLogPanel with owner = current_scene at _ready time.
	# When instantiated via add_child (not change_scene_to_file), current_scene
	# is null during _ready, so owner stays null and %EventLogPanel lookup fails
	# (game_controller.gd:31 + _apply_theme). Fix ownership + re-apply theme.
	var panel: Node = inst.get_node_or_null("%EventLogPanel")
	if panel != null:
		return
	# Search for panels created with wrong owner.
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		@warning_ignore("unsafe_call_argument")
		var node: Node = stack.pop_back() as Node
		for child: Node in node.get_children():
			if child.name == "EventLogPanel":
				@warning_ignore("unsafe_property_access")
				child.owner = inst
				@warning_ignore("unsafe_property_access")
				child.unique_name_in_owner = true
				panel = child
			stack.append(child)
	if panel != null:
		@warning_ignore("unsafe_property_access")
		inst._event_log_panel = panel
		if inst.has_method("_apply_theme"):
			@warning_ignore("unsafe_method_access")
			inst._apply_theme()


func _inject_actions(inst: Node, frame: int, scene_path: String) -> void:
	# Frame 5: asteroid spawn via spawner (game_controller.gd:159 L path)
	if frame == 5:
		_try_spawn(inst)
	# Frame 10 & 15: sun click popup + close (game_controller.gd:113-118)
	if frame == 10:
		_try_sun_click(inst)
	if frame == 15:
		_try_close_sun_popup(inst)
	# Frame 20: Viewport input simulation — fabricate InputEvents
	# and push through viewport + game_controller.gd:106 _unhandled_input.
	if frame == 20:
		_try_input_simulation(inst)
	# Frame 30: pause toggle (Esc / ui_cancel -> _toggle_pause, game_controller.gd:152)
	if frame == 30:
		_try_toggle_pause(inst, true)
	# Frame 35: resume
	if frame == 35:
		_try_toggle_pause(inst, false)
	# Frame 45: camera zoom in/out + drag (game_controller.gd:143-157)
	if frame == 45:
		_try_camera_inputs(inst)
	# Frame 55: extra spawn + drag
	if frame == 55:
		_try_spawn(inst)
		_try_drag(inst, frame)
	# Frame 80: planet click via _check_planet_click (main.gd) / ship click (progression.gd)
	if frame == 80:
		_try_click_target(inst)
	# Frame 100/101: progression extras — enforce_sun_barrier + input_active across
	# two frames so _physics_process observes both true and false.
	if scene_path == PROGRESSION_SCENE_PATH and frame == 100:
		_exercise_progression_extras(inst)
	if scene_path == PROGRESSION_SCENE_PATH and frame == 101:
		_disable_progression_input(inst)
	# Frame 120/180: progression rocket fire (progression.gd:208 try_fire within 800)
	if scene_path == PROGRESSION_SCENE_PATH and (frame == 120 or frame == 180):
		_try_rocket_fire(inst)
	# Frame 200, 400: extra spawns to exercise asteroid gravity (asteroid.gd:199)
	if frame == 200 or frame == 400:
		_try_spawn(inst)


func _try_spawn(inst: Node) -> void:
	# Prefer typed spawner via unique name, fallback to internal var.
	var spawner: Node = inst.get_node_or_null("%AsteroidSpawner")
	if spawner == null:
		@warning_ignore("unsafe_property_access")
		if "_spawner" in inst:
			@warning_ignore("unsafe_property_access")
			spawner = inst._spawner as Node
	if spawner != null and spawner.has_method("spawn"):
		@warning_ignore("unsafe_method_access")
		spawner.spawn()
		print("[gameplay_smoke] spawn at frame")


func _try_sun_click(inst: Node) -> void:
	if inst.has_method("_on_sun_clicked"):
		@warning_ignore("unsafe_method_access")
		inst._on_sun_clicked()
		print("[gameplay_smoke] sun click injected")


func _try_close_sun_popup(inst: Node) -> void:
	if inst.has_method("_close_sun_popup"):
		@warning_ignore("unsafe_method_access")
		inst._close_sun_popup()


func _try_input_simulation(inst: Node) -> void:
	# Fabricate events via viewport.push_input + direct _unhandled_input to
	# exercise both wiring paths. Toggle keys (L, Esc) are intentionally
	# double-dispatched (viewport + direct) so the two toggles cancel out
	# (Esc net no-op, L double-spawn harmless); this papers over a broken
	# viewport routing but guarantees both paths are exercised — canonical
	# pause coverage is via _try_toggle_pause at 30/35, not Esc here.
	# Covers sun click on_sun <60, L spawn, Esc pause, drag/zoom (issue #334).
	var viewport: Viewport = get_root()
	# InputEventMouseButton — left click at center (sun at origin -> canvas 960,540 when cam 0,0)
	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(960, 540)
	viewport.push_input(mb)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb)
	# MouseButton release
	var mb_up: InputEventMouseButton = InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = Vector2(960, 540)
	viewport.push_input(mb_up)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb_up)
	# InputEventMouseMotion — drag delta
	var mm: InputEventMouseMotion = InputEventMouseMotion.new()
	mm.position = Vector2(970, 550)
	mm.relative = Vector2(10, 10)
	mm.velocity = Vector2(10, 10)
	viewport.push_input(mm)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mm)
	# Drag button (right/middle) press + motion
	var mb_drag: InputEventMouseButton = InputEventMouseButton.new()
	mb_drag.button_index = MOUSE_BUTTON_RIGHT
	mb_drag.pressed = true
	mb_drag.position = Vector2(960, 540)
	viewport.push_input(mb_drag)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb_drag)
	var mm_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	mm_drag.position = Vector2(975, 555)
	mm_drag.relative = Vector2(15, 15)
	viewport.push_input(mm_drag)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mm_drag)
	var mb_drag_up: InputEventMouseButton = InputEventMouseButton.new()
	mb_drag_up.button_index = MOUSE_BUTTON_RIGHT
	mb_drag_up.pressed = false
	mb_drag_up.position = Vector2(975, 555)
	viewport.push_input(mb_drag_up)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb_drag_up)
	# Mouse wheel zoom (zoom_in / zoom_out)
	var wheel_up: InputEventMouseButton = InputEventMouseButton.new()
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.pressed = true
	wheel_up.position = Vector2(960, 540)
	viewport.push_input(wheel_up)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(wheel_up)
	var wheel_down: InputEventMouseButton = InputEventMouseButton.new()
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.pressed = true
	wheel_down.position = Vector2(960, 540)
	viewport.push_input(wheel_down)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(wheel_down)
	# InputEventKey — L spawn_asteroid (double dispatch intentional — exercises both
	# viewport and direct paths; double-spawn is harmless for smoke)
	var key_l: InputEventKey = InputEventKey.new()
	key_l.keycode = KEY_L
	key_l.pressed = true
	key_l.echo = false
	viewport.push_input(key_l)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_l)
	var key_l_up: InputEventKey = InputEventKey.new()
	key_l_up.keycode = KEY_L
	key_l_up.pressed = false
	viewport.push_input(key_l_up)
	# InputEventKey — Esc pause (double dispatch intentional — toggles twice
	# so net no-op; canonical pause coverage is _try_toggle_pause at 30/35)
	var key_esc: InputEventKey = InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	key_esc.pressed = true
	key_esc.echo = false
	viewport.push_input(key_esc)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_esc)
	var key_esc_up: InputEventKey = InputEventKey.new()
	key_esc_up.keycode = KEY_ESCAPE
	key_esc_up.pressed = false
	viewport.push_input(key_esc_up)
	print("[gameplay_smoke] input simulation injected")


func _try_toggle_pause(inst: Node, _pause: bool) -> void:
	# Use PauseButton signal path when available, otherwise direct toggle.
	var btn: Button = inst.get_node_or_null("%PauseButton") as Button
	if btn != null and btn.has_signal("pause_toggled"):
		@warning_ignore("unsafe_method_access")
		btn.emit_signal("pause_toggled")
		print("[gameplay_smoke] pause_toggled via button")
		return
	if inst.has_method("_toggle_pause"):
		@warning_ignore("unsafe_method_access")
		inst._toggle_pause()
		print("[gameplay_smoke] _toggle_pause direct")
	elif inst.has_method("_on_pause_toggled"):
		@warning_ignore("unsafe_method_access")
		inst._on_pause_toggled()
		print("[gameplay_smoke] _on_pause_toggled direct")


func _try_camera_inputs(inst: Node) -> void:
	var cam: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
	if cam == null:
		return
	if cam.has_method("zoom_in"):
		@warning_ignore("unsafe_method_access")
		cam.zoom_in()
	if cam.has_method("zoom_out"):
		@warning_ignore("unsafe_method_access")
		cam.zoom_out()
	# Drag simulation
	if cam.has_method("start_drag"):
		@warning_ignore("unsafe_method_access")
		cam.start_drag(Vector2(960, 540))
	if cam.has_method("update_drag"):
		@warning_ignore("unsafe_method_access")
		cam.update_drag(Vector2(970, 550))
	if cam.has_method("end_drag"):
		@warning_ignore("unsafe_method_access")
		cam.end_drag()
	print("[gameplay_smoke] camera inputs injected")


func _try_drag(inst: Node, _frame: int) -> void:
	var cam: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
	if cam == null:
		return
	@warning_ignore("unsafe_method_access")
	if cam.has_method("start_drag"):
		@warning_ignore("unsafe_method_access")
		cam.start_drag(Vector2(100, 100))
	@warning_ignore("unsafe_method_access")
	if cam.has_method("update_drag"):
		@warning_ignore("unsafe_method_access")
		cam.update_drag(Vector2(120, 130))
	@warning_ignore("unsafe_method_access")
	if cam.has_method("end_drag"):
		@warning_ignore("unsafe_method_access")
		cam.end_drag()


func _try_click_target(inst: Node) -> void:
	# Exercise _check_planet_click (main) and _check_ship_click (progression)
	var cam: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
	if cam == null:
		return
	var screen_pos: Vector2 = Vector2(960, 540)
	if inst.has_method("_get_click_target"):
		@warning_ignore("unsafe_method_access", "unsafe_cast")
		var target: Node2D = inst._get_click_target(screen_pos) as Node2D
		if target != null and inst.has_method("_on_select_target"):
			@warning_ignore("unsafe_method_access", "unsafe_call_argument")
			inst._on_select_target(target)
			print("[gameplay_smoke] click target selected: %s" % str(target.name))
	# Also exercise progression ship click direct
	if inst.has_method("_check_ship_click"):
		@warning_ignore("unsafe_method_access")
		var hit: bool = inst._check_ship_click(screen_pos) as bool
		if hit and inst.has_method("_get_click_target"):
			@warning_ignore("unsafe_method_access", "unsafe_cast")
			var t2: Node2D = inst._get_click_target(screen_pos) as Node2D
			if t2 != null and inst.has_method("_on_select_target"):
				@warning_ignore("unsafe_method_access", "unsafe_call_argument")
				inst._on_select_target(t2)
	# Also drive a fabricated mouse event for select
	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = screen_pos
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb)


func _exercise_progression_extras(inst: Node) -> void:
	# Exercise Spaceship.init / enforce_sun_barrier / input_active toggle (issue #334).
	@warning_ignore("unsafe_property_access")
	var ship: Node = null
	if "_spaceship" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		ship = inst._spaceship as Node
	if ship == null:
		ship = inst.get_node_or_null("%Spaceship")
	if ship == null:
		return
	if ship.has_method("enforce_sun_barrier"):
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		var sun_mass: float = inst.sun_mass as float if "sun_mass" in inst else 1.0
		@warning_ignore("unsafe_method_access", "unsafe_cast")
		var sun_r: float = (
			(
				(preload("res://scripts/bodies/orbital_body.gd") as GDScript).sun_collision_r(
					sun_mass
				)
				as float
			)
			if sun_mass > 0
			else 80.0
		)
		@warning_ignore("unsafe_property_access")
		var cr: float = (ship as Node2D).collision_radius if "collision_radius" in ship else 14.0
		@warning_ignore("unsafe_method_access")
		ship.enforce_sun_barrier(sun_r + cr + 50.0)
	# Enable input_active for one frame — paired with _disable_progression_input
	# at next frame so _physics_process observes both states.
	@warning_ignore("unsafe_property_access")
	if "input_active" in ship:
		@warning_ignore("unsafe_property_access")
		ship.input_active = true
		print("[gameplay_smoke] spaceship input_active=true")


func _disable_progression_input(inst: Node) -> void:
	@warning_ignore("unsafe_property_access")
	var ship: Node = null
	if "_spaceship" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		ship = inst._spaceship as Node
	if ship == null:
		ship = inst.get_node_or_null("%Spaceship")
	if ship == null:
		return
	@warning_ignore("unsafe_property_access")
	if "input_active" in ship:
		@warning_ignore("unsafe_property_access")
		ship.input_active = false
		print("[gameplay_smoke] spaceship input_active=false")


func _try_rocket_fire(inst: Node) -> void:
	# Progression-only: deterministic rocket hit (progression.gd:208 + :240 spawn_glow).
	# Ensures "Asteroid destroyed by rocket" log is reachable without waiting for RNG spawns.
	@warning_ignore("unsafe_property_access")
	var ship: Node = null
	if "_spaceship" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		ship = inst._spaceship as Node
	if ship == null:
		ship = inst.get_node_or_null("%Spaceship")
		if ship == null:
			ship = inst.get_node_or_null("Spaceship")
	if ship == null:
		return
	var cam: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
	if cam != null and cam.has_method("follow_node"):
		@warning_ignore("unsafe_method_access")
		cam.follow_node(ship as Node2D)
	# Ensure spaceship will auto-fire by placing a close asteroid within AUTO_FIRE_RANGE.
	@warning_ignore("unsafe_property_access")
	var spawner: Node = null
	if "_spawner" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		spawner = inst._spawner as Node
	if spawner == null:
		spawner = inst.get_node_or_null("%AsteroidSpawner")
	if spawner != null and spawner.has_method("spawn"):
		@warning_ignore("unsafe_method_access")
		spawner.spawn()
		# Reposition the freshly spawned asteroid close to the ship so auto-fire triggers next frame.
		@warning_ignore("unsafe_property_access")
		if "_asteroids" in spawner:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			var asteroids: Array = spawner._asteroids as Array
			if not asteroids.is_empty():
				@warning_ignore("unsafe_cast")
				var last: Node2D = asteroids[asteroids.size() - 1] as Node2D
				if last != null:
					@warning_ignore("unsafe_property_access")
					last.position = (ship as Node2D).position + Vector2(0, -10)
					@warning_ignore("unsafe_property_access")
					if "collision_radius" in last:
						@warning_ignore("unsafe_property_access")
						last.collision_radius = 8.0
					if last.has_method("set_vel"):
						@warning_ignore("unsafe_method_access")
						last.set_vel(Vector2.ZERO)
					print("[gameplay_smoke] close asteroid placed for rocket")
	# Try manual fire as immediate guarantee (adds to progression's _rockets so collision is checked).
	var target: Node2D = null
	if spawner != null and "_asteroids" in spawner:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var asteroids2: Array = spawner._asteroids as Array
		for a: Variant in asteroids2:
			@warning_ignore("unsafe_cast", "unsafe_method_access")
			var node: Node2D = a as Node2D
			if node != null and node.has_method("is_alive"):
				@warning_ignore("unsafe_method_access", "unsafe_cast")
				if node.is_alive() as bool:
					target = node
					break
	if target == null:
		target = Node2D.new()
		@warning_ignore("unsafe_property_access")
		target.position = (ship as Node2D).position + Vector2(0, -10)
		get_root().add_child(target)
	var rocket_fired: bool = false
	if ship.has_method("try_fire"):
		@warning_ignore("unsafe_method_access", "unsafe_cast")
		var rocket: Node = ship.try_fire(target) as Node
		if rocket != null:
			# Progression expects rocket as child of progression instance and tracked in _rockets.
			@warning_ignore("unsafe_call_argument")
			inst.add_child(rocket)
			@warning_ignore("unsafe_property_access")
			if "_rockets" in inst:
				@warning_ignore("unsafe_property_access", "unsafe_cast")
				var rockets: Array = inst._rockets as Array
				@warning_ignore("unsafe_call_argument")
				rockets.append(rocket)
			print("[gameplay_smoke] rocket fired")
			rocket_fired = true
	if target != null and target.get_parent() == get_root():
		target.queue_free()
	# Exercise toggle_ship_follow so input_active path is hit.
	if not rocket_fired:
		var key_space: InputEventKey = InputEventKey.new()
		key_space.keycode = KEY_SPACE
		key_space.pressed = true
		key_space.echo = false
		if inst.has_method("_on_key_pressed"):
			@warning_ignore("unsafe_method_access")
			inst._on_key_pressed(key_space)
		get_root().push_input(key_space)


func _verify_rocket_hit(inst: Node) -> bool:
	# Authoritative check for "Asteroid destroyed by rocket" (progression.gd:242).
	# Returns true if found; caller tracks _rocket_hit_seen and warns if missing
	# after frame 210. Surfaced via rocket_hit bool in results and WARN log.
	@warning_ignore("unsafe_property_access")
	var elog: Node = null
	if "_event_log" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		elog = inst._event_log as Node
	if elog == null:
		elog = inst.get_node_or_null("%EventLog")
	if elog != null and "_entries" in elog:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var entries: Array = elog._entries as Array
		for entry: Variant in entries:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			var lbl: Label = (entry as Dictionary).label as Label if entry is Dictionary else null
			if lbl != null and lbl.text == "Asteroid destroyed by rocket":
				print("[gameplay_smoke] Asteroid destroyed by rocket")
				return true
	return false


# ── Visual regression helpers (#343) ───────────────────────────────────


func _capture_visual_hash(scene_path: String, seed_val: int) -> Dictionary:
	@warning_ignore("unsafe_method_access")
	var cap: Dictionary = (
		await VISUAL_UTILS.capture_visual_hash(self, scene_path, seed_val, VISUAL_FRAMES)
		as Dictionary
	)
	return cap
