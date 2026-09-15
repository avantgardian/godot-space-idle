extends SceneTree

## Smoke-loads every .tscn / .tres under res://scenes and res://resources.
## Exits 1 if any load fails (returns null). Used by CI typing gate (#313)
## to catch broken scene/resource references that --editor --quit logs as
## ERROR but still exits 0 (so grep alone is required, but smoke is stronger).
## Strict typing enforced (warnings=2) — all vars/methods typed.

const SCAN_ROOTS: Array[String] = ["res://scenes", "res://resources"]


func _init() -> void:
	var failed: bool = false
	for root_path: String in SCAN_ROOTS:
		failed = _scan_dir(root_path, failed) or failed
	# Also probe the top-level theme directly (in case DirAccess misses it
	# due to import cache quirks — belt and braces).
	var extra_paths: Array[String] = [
		"res://project.godot",
		"res://resources/game_theme.tres",
	]
	for extra_path: String in extra_paths:
		if extra_path.ends_with(".tres") or extra_path.ends_with(".tscn"):
			if not _try_load(extra_path):
				failed = true
	if failed:
		printerr("[resource_smoke] FAIL — one or more resources failed to load")
		quit(1)
	else:
		print("[resource_smoke] PASS — all scenes/resources loaded")
		quit(0)


func _scan_dir(dir_path: String, failed: bool) -> bool:
	var has_failed: bool = failed
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		printerr("[resource_smoke] Cannot open dir: %s" % dir_path)
		return true
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		# Skip hidden / import artifacts and .uid files.
		if (
			file_name.begins_with(".")
			or file_name.ends_with(".import")
			or file_name.ends_with(".uid")
		):
			file_name = dir.get_next()
			continue
		var full_path: String = dir_path + "/" + file_name
		if dir.current_is_dir():
			has_failed = _scan_dir(full_path, has_failed) or has_failed
		elif file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
			if not _try_load(full_path):
				has_failed = true
		file_name = dir.get_next()
	dir.list_dir_end()
	return has_failed


func _try_load(path: String) -> bool:
	# ResourceLoader.exists distinguishes missing files before load logs ERROR.
	if not ResourceLoader.exists(path):
		printerr("[resource_smoke] Missing: %s (ResourceLoader.exists == false)" % path)
		return false
	var res: Resource = load(path) as Resource
	if res == null:
		printerr("[resource_smoke] Failed to load: %s (load returned null)" % path)
		return false
	print("[resource_smoke] OK: %s" % path)
	return true
