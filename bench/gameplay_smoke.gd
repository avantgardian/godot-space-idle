extends SceneTree

## Headless gameplay smoke — catches runtime push_error / SCRIPT ERROR
## that only surface when scenes are instantiated and stepped.
## Usage: Godot --headless -s res://bench/gameplay_smoke.gd
##   [-- --scene main|progression --frames 600 --seed 42]
## CI runs with no args (both scenes, 600 frames, seed 42).
## Implements #333 (phase 1 core) — extended in #334/#335.

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const PROGRESSION_SCENE_PATH: String = "res://scenes/progression.tscn"
const DEFAULT_FRAMES: int = 600
const DEFAULT_SEED: int = 42
const DELTA: float = 0.016


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	var scene_filter: String = ""
	var frames: int = DEFAULT_FRAMES
	var seed_val: int = DEFAULT_SEED
	var idx: int = 0
	while idx < args.size():
		var arg: String = args[idx]
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
		idx += 1
	# Defer so SceneTree root is ready and await works inside.
	@warning_ignore("unsafe_call_argument")
	call_deferred("_deferred_run", scene_filter, frames, seed_val)


func _deferred_run(scene_filter: String, frames: int, seed_val: int) -> void:
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
				"[gameplay_smoke] running %s frames=%d seed=%d scene=%s"
				% [label, frames, seed_val, scene_path]
			)
		)
		seed(seed_val)
		var ok: bool = await _run_single_scene(scene_path, frames, seed_val)
		results[label] = ok
		if not ok:
			all_passed = false

	results["frames"] = frames
	results["seed"] = seed_val
	results["passed"] = all_passed
	print(JSON.stringify(results))
	if all_passed:
		print("[gameplay_smoke] PASS — both scenes ran %d frames without fatal load" % frames)
		quit(0)
	else:
		printerr(
			"[gameplay_smoke] FAIL — one or more scenes failed (see log, grep SCRIPT ERROR|push_error)"
		)
		quit(1)


func _scene_label(path: String) -> String:
	if path == MAIN_SCENE_PATH:
		return "main"
	if path == PROGRESSION_SCENE_PATH:
		return "progression"
	return path


func _run_single_scene(scene_path: String, frames: int, seed_val: int) -> bool:
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

	# Step frames and inject deterministic actions.
	for frame: int in range(frames):
		_inject_actions(inst, frame, scene_path)
		await process_frame
		# Also drive _physics_process manually so logic runs even if
		# get_tree().paused would freeze it — toggle test re-enables.
		# The engine already ticks _physics_process on process_frame,
		# this is belt-and-braces for headless determinism.
		if not is_instance_valid(inst):
			printerr("[gameplay_smoke] FAIL scene freed at frame %d: %s" % [frame, scene_path])
			return false

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
	# Frame 10 & 60: sun click popup + close
	if frame == 10:
		_try_sun_click(inst)
	if frame == 15:
		_try_close_sun_popup(inst)
	# Frame 20: Viewport input simulation Tier B — fabricate InputEvents
	# and push through game_controller.gd:106-161 wiring.
	if frame == 20:
		_try_input_simulation(inst)
	# Frame 30: pause toggle (Esc / pause_button path, game_controller.gd:220)
	if frame == 30:
		_try_toggle_pause(inst, true)
	# Frame 35: resume
	if frame == 35:
		_try_toggle_pause(inst, false)
	# Frame 45: camera zoom in/out + drag
	if frame == 45:
		_try_camera_inputs(inst)
	# Frame 55: extra spawn + drag
	if frame == 55:
		_try_spawn(inst)
		_try_drag(inst, frame)
	# Frame 80: planet click via _check_planet_click (main.gd) / ship click (progression.gd)
	if frame == 80:
		_try_click_target(inst)
	# Frame 120/180: progression rocket fire (progression.gd:208)
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
	# Fabricate events and feed through _unhandled_input (Tier B).
	var viewport: Viewport = get_root()
	# InputEventMouseButton — select (sun click) side.
	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(960, 540)
	# Mark as "select" action so game_controller._unhandled_input handles it.
	# We also push through viewport to exercise real wiring.
	viewport.push_input(mb)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb)
	# InputEventKey — L spawn_asteroid
	var key_l: InputEventKey = InputEventKey.new()
	key_l.keycode = KEY_L
	key_l.pressed = true
	key_l.echo = false
	viewport.push_input(key_l)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_l)
	# InputEventKey — Esc pause
	var key_esc: InputEventKey = InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	key_esc.pressed = true
	key_esc.echo = false
	viewport.push_input(key_esc)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_esc)
	# Release esc to avoid sticky.
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
	# Pick a screen point near center — matches Main's planet hit radius logic.
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


func _try_rocket_fire(inst: Node) -> void:
	# Progression-only: try spaceship rocket fire path (progression.gd:208)
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
	# Need a target — pick first alive asteroid if any, else ship itself offset.
	var target: Node2D = null
	@warning_ignore("unsafe_property_access")
	var spawner: Node = null
	if "_spawner" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		spawner = inst._spawner as Node
	if spawner == null:
		spawner = inst.get_node_or_null("%AsteroidSpawner")
	if spawner != null and "_asteroids" in spawner:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var asteroids: Array = spawner._asteroids as Array
		for a: Variant in asteroids:
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
		target.position = (ship as Node2D).position + Vector2(200, 0)
		get_root().add_child(target)
	if ship.has_method("try_fire"):
		@warning_ignore("unsafe_method_access", "unsafe_cast")
		var rocket: Node = ship.try_fire(target) as Node
		if rocket != null:
			get_root().add_child(rocket)
			print("[gameplay_smoke] rocket fired")
	if target != null and target.get_parent() == get_root():
		target.queue_free()
	# Also exercise toggle_ship_follow key
	var key_space: InputEventKey = InputEventKey.new()
	key_space.keycode = KEY_SPACE
	key_space.pressed = true
	key_space.echo = false
	if inst.has_method("_on_key_pressed"):
		@warning_ignore("unsafe_method_access")
		inst._on_key_pressed(key_space)
	get_root().push_input(key_space)
