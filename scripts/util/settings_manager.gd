class_name SettingsManager
extends RefCounted

const PATH: String = "user://settings.cfg"

const REBINDABLE_ACTIONS: Array[String] = [
	"ui_cancel",
	"zoom_in",
	"zoom_out",
	"spawn_asteroid",
	"ship_rotate_left",
	"ship_rotate_right",
	"ship_thrust_forward",
	"ship_thrust_reverse",
	"toggle_ship_follow",
]

var reduced_motion: bool = false
var screen_shake: bool = true
var colorblind_mode: int = 0
var _file: ConfigFile


func _init() -> void:
	_file = ConfigFile.new()
	_load()


func _load() -> void:
	var err: int = _file.load(PATH)
	if err != OK:
		_save_defaults()
		return
	@warning_ignore("unsafe_cast")
	reduced_motion = _file.get_value("accessibility", "reduced_motion", false) as bool
	@warning_ignore("unsafe_cast")
	screen_shake = _file.get_value("accessibility", "screen_shake", true) as bool
	@warning_ignore("unsafe_cast")
	colorblind_mode = _file.get_value("accessibility", "colorblind_mode", 0) as int
	_load_keybindings()


func _save_defaults() -> void:
	_file.set_value("accessibility", "reduced_motion", false)
	_file.set_value("accessibility", "screen_shake", true)
	_file.set_value("accessibility", "colorblind_mode", 0)
	_save_keybindings(_default_keybindings())
	_file.save(PATH)


func save() -> void:
	_file.set_value("accessibility", "reduced_motion", reduced_motion)
	_file.set_value("accessibility", "screen_shake", screen_shake)
	_file.set_value("accessibility", "colorblind_mode", colorblind_mode)
	_save_keybindings(_current_keybindings())
	_file.save(PATH)


func _default_keybindings() -> Dictionary:
	var out: Dictionary = {}
	for action: String in REBINDABLE_ACTIONS:
		@warning_ignore("unsafe_cast")
		var events: Array[InputEvent] = (
			InputMap.action_get_events(action) if InputMap.has_action(action) else []
			as Array[InputEvent]
		)
		var scancodes: Array[int] = []
		for ev: InputEvent in events:
			if ev is InputEventKey:
				scancodes.append((ev as InputEventKey).keycode)
		out[action] = scancodes
	return out


func _current_keybindings() -> Dictionary:
	var out: Dictionary = {}
	for action: String in REBINDABLE_ACTIONS:
		var scancodes: Array[int] = []
		if InputMap.has_action(action):
			@warning_ignore("unsafe_cast")
			var evs: Array[InputEvent] = InputMap.action_get_events(action) as Array[InputEvent]
			for ev: InputEvent in evs:
				if ev is InputEventKey:
					scancodes.append((ev as InputEventKey).keycode)
		out[action] = scancodes
	return out


func _save_keybindings(bindings: Dictionary) -> void:
	for action: String in REBINDABLE_ACTIONS:
		@warning_ignore("unsafe_cast")
		var scancodes: Array = bindings.get(action, []) as Array
		_file.set_value("bindings", action, scancodes)


func _load_keybindings() -> void:
	for action: String in REBINDABLE_ACTIONS:
		if not _file.has_section_key("bindings", action):
			continue
		@warning_ignore("unsafe_cast")
		var stored: Array = _file.get_value("bindings", action, []) as Array
		if stored.is_empty():
			continue
		if not InputMap.has_action(action):
			continue
		@warning_ignore("unsafe_cast")
		var existing: Array[InputEvent] = InputMap.action_get_events(action) as Array[InputEvent]
		for ev: InputEvent in existing:
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		for code: Variant in stored:
			var ke: InputEventKey = InputEventKey.new()
			@warning_ignore("unsafe_cast")
			ke.keycode = code as Key
			InputMap.action_add_event(action, ke)


func set_keybinding(action: String, scancodes: Array[int]) -> void:
	if not action in REBINDABLE_ACTIONS:
		return
	if not InputMap.has_action(action):
		return
	@warning_ignore("unsafe_cast")
	var evs: Array[InputEvent] = InputMap.action_get_events(action) as Array[InputEvent]
	for ev: InputEvent in evs:
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	for code: int in scancodes:
		var ke: InputEventKey = InputEventKey.new()
		@warning_ignore("unsafe_cast")
		ke.keycode = code as Key
		InputMap.action_add_event(action, ke)
	save()
