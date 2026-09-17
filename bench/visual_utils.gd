extends RefCounted

## Visual regression helpers (#343) — shader source hashing + baseline IO.
## Extracted from gameplay_smoke.gd to keep file under gdlint 1000-line cap.


static func hash_bytes(data: PackedByteArray) -> String:
	var ctx: HashingContext = HashingContext.new()
	@warning_ignore("unsafe_method_access")
	ctx.start(HashingContext.HASH_SHA256)
	@warning_ignore("unsafe_method_access")
	ctx.update(data)
	@warning_ignore("unsafe_method_access")
	var out: PackedByteArray = ctx.finish()
	return out.hex_encode()


static func hash_shader_sources() -> String:
	var ctx: HashingContext = HashingContext.new()
	@warning_ignore("unsafe_method_access")
	ctx.start(HashingContext.HASH_SHA256)
	var files: Array[String] = collect_shader_files("res://shaders")
	files.sort()
	for path: String in files:
		var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
		if fa != null:
			var buf: PackedByteArray = fa.get_buffer(int(fa.get_length()))
			@warning_ignore("unsafe_method_access")
			ctx.update(buf)
			@warning_ignore("unsafe_method_access")
			ctx.update(path.to_utf8_buffer())
		else:
			@warning_ignore("unsafe_method_access")
			ctx.update(path.to_utf8_buffer())
	@warning_ignore("unsafe_method_access")
	var out: PackedByteArray = ctx.finish()
	return out.hex_encode()


static func collect_shader_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.begins_with("."):
			fname = dir.get_next()
			continue
		var full: String = dir_path + "/" + fname
		if dir.current_is_dir():
			var sub: Array[String] = collect_shader_files(full)
			for s: String in sub:
				out.append(s)
		elif fname.ends_with(".gdshader") or fname.ends_with(".gdshaderinc"):
			out.append(full)
		fname = dir.get_next()
	dir.list_dir_end()
	return out


static func load_visual_baseline(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return {}
	var txt: String = fa.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		@warning_ignore("unsafe_cast")
		return parsed as Dictionary
	return {}


static func save_visual_baseline(
	path: String, current: Dictionary, targets: Array[String], visual_frames: int, tolerance: float
) -> void:
	var out: Dictionary = {}
	for t: String in targets:
		var label: String = t
		if t.begins_with("res://"):
			if t == "res://scenes/main.tscn":
				label = "main"
			elif t == "res://scenes/progression.tscn":
				label = "progression"
		if current.has(label):
			out[label] = current[label]
	if current.has("shader_hash"):
		out["shader_hash"] = current["shader_hash"]
	out["frames"] = visual_frames
	out["seed"] = current.get("seed", 42)
	out["tolerance"] = tolerance
	out["generated_at"] = current.get("generated_at", "")
	out["viewport_available"] = false
	for t2: String in targets:
		var l2: String = t2
		if t2.begins_with("res://"):
			if t2 == "res://scenes/main.tscn":
				l2 = "main"
			elif t2 == "res://scenes/progression.tscn":
				l2 = "progression"
		var key: String = l2 + "_viewport_available"
		if current.get(key, false) as bool:
			out["viewport_available"] = true
			break
	var local_path: String = path.replace("res://", "./")
	var fa2: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
	if fa2 != null:
		fa2.store_string(JSON.stringify(out, "\t"))
		print("[visual_smoke] wrote baseline %s: %s" % [local_path, JSON.stringify(out)])
	else:
		printerr("[visual_smoke] FAIL write baseline %s" % local_path)


static func capture_visual_hash(
	tree: SceneTree, scene_path: String, seed_val: int, visual_frames: int
) -> Dictionary:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		printerr("[visual_smoke] FAIL load null: %s" % scene_path)
		var sh: String = hash_shader_sources() as String
		return {
			"viewport_hash": "",
			"combined_hash": sh,
			"viewport_available": false,
			"image_size": Vector2i(0, 0),
			"png_path": "",
			"shader_hash": sh,
		}
	var inst: Node = packed.instantiate()
	if inst == null:
		printerr("[visual_smoke] FAIL instantiate null: %s" % scene_path)
		var sh2: String = hash_shader_sources() as String
		return {
			"viewport_hash": "",
			"combined_hash": sh2,
			"viewport_available": false,
			"image_size": Vector2i(0, 0),
			"png_path": "",
			"shader_hash": sh2,
		}
	@warning_ignore("unsafe_property_access")
	if "star_seed" in inst:
		@warning_ignore("unsafe_property_access")
		inst.star_seed = seed_val
	var prev_scene: Node = tree.current_scene
	@warning_ignore("unsafe_call_argument")
	tree.get_root().add_child(inst)
	if tree.current_scene != inst:
		tree.current_scene = inst
	await tree.process_frame
	await tree.process_frame
	_fix_panel_for_visual(inst)
	for _i: int in range(visual_frames):
		await tree.process_frame
		if not is_instance_valid(inst):
			break
	var viewport_hash: String = ""
	var viewport_available: bool = false
	var img_size: Vector2i = Vector2i(0, 0)
	var png_path: String = ""
	# Headless dummy renderer has no viewport texture — skip capture to avoid
	# `texture_2d_get: Parameter "t" is null` ERROR that trips CI ERR_PAT.
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	var is_headless: bool = DisplayServer.get_name() == "headless"
	var vp_tex: ViewportTexture = null
	if not is_headless:
		var vp: Window = tree.get_root()
		await tree.process_frame
		@warning_ignore("unsafe_property_access")
		vp_tex = vp.get_texture() as ViewportTexture
	else:
		print("[visual_smoke] headless display — skip viewport capture (shader hash only)")
	var img: Image = null
	if vp_tex != null:
		@warning_ignore("unsafe_method_access")
		img = vp_tex.get_image()
	if not is_headless:
		if img != null and img.get_width() > 0 and img.get_height() > 0:
			img_size = Vector2i(img.get_width(), img.get_height())
			var data: PackedByteArray = img.get_data()
			var is_empty: bool = true
			var check_len: int = mini(1024, data.size())
			for k: int in range(check_len):
				if data[k] != 0:
					is_empty = false
					break
			if is_empty and data.size() > 0:
				print("[visual_smoke] WARN viewport all-zero — shader fallback")
			else:
				viewport_hash = hash_bytes(data)
				viewport_available = true
				var label: String = _label_for_path(scene_path)
				var save_path: String = "res://bench/visual_current_%s.png" % label
				@warning_ignore("return_value_discarded")
				img.save_png(save_path)
				png_path = save_path
				print(
					(
						"[visual_smoke] viewport %s %dx%d hash=%s"
						% [label, img_size.x, img_size.y, viewport_hash.substr(0, 16)]
					)
				)
		else:
			print("[visual_smoke] WARN no viewport image — shader fallback")
	var shader_hash: String = hash_shader_sources() as String
	var combined: String
	if viewport_available:
		combined = hash_bytes((viewport_hash + shader_hash).to_utf8_buffer()) as String
	else:
		combined = shader_hash
	if is_instance_valid(inst):
		inst.queue_free()
		await tree.process_frame
	if prev_scene != null and is_instance_valid(prev_scene):
		tree.current_scene = prev_scene
	else:
		tree.current_scene = null
	return {
		"viewport_hash": viewport_hash,
		"combined_hash": combined,
		"viewport_available": viewport_available,
		"image_size": img_size,
		"png_path": png_path,
		"shader_hash": shader_hash,
	}


static func _label_for_path(path: String) -> String:
	if path == "res://scenes/main.tscn":
		return "main"
	if path == "res://scenes/progression.tscn":
		return "progression"
	return path


static func _fix_panel_for_visual(inst: Node) -> void:
	var panel: Node = inst.get_node_or_null("%EventLogPanel")
	if panel != null:
		return
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


static func try_pixel_diff(label: String) -> float:
	var base_png: String = "res://bench/visual_baseline_%s.png" % label
	var cur_png: String = "res://bench/visual_current_%s.png" % label
	if not FileAccess.file_exists(base_png) or not FileAccess.file_exists(cur_png):
		return -1.0
	var base_img: Image = Image.load_from_file(base_png)
	var cur_img: Image = Image.load_from_file(cur_png)
	if base_img == null or cur_img == null:
		return -1.0
	if base_img.get_width() != cur_img.get_width() or base_img.get_height() != cur_img.get_height():
		return 1.0
	var w: int = base_img.get_width()
	var h: int = base_img.get_height()
	var total: int = w * h
	var diff: int = 0
	for y: int in range(h):
		for x: int in range(w):
			if base_img.get_pixel(x, y) != cur_img.get_pixel(x, y):
				diff += 1
	return float(diff) / float(total)
