class_name SettingsManager
extends RefCounted

const PATH := "user://settings.cfg"

const REBINDABLE_ACTIONS: Array[String] = [
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

func _init():
	_file = ConfigFile.new()
	_load()

func _load():
	var err := _file.load(PATH)
	if err != OK:
		_save_defaults()
		return
	reduced_motion = _file.get_value("accessibility", "reduced_motion", false)
	screen_shake = _file.get_value("accessibility", "screen_shake", true)
	colorblind_mode = _file.get_value("accessibility", "colorblind_mode", 0)
	_load_keybindings()

func _save_defaults():
	_file.set_value("accessibility", "reduced_motion", false)
	_file.set_value("accessibility", "screen_shake", true)
	_file.set_value("accessibility", "colorblind_mode", 0)
	_save_keybindings(_default_keybindings())
	_file.save(PATH)

func save():
	_file.set_value("accessibility", "reduced_motion", reduced_motion)
	_file.set_value("accessibility", "screen_shake", screen_shake)
	_file.set_value("accessibility", "colorblind_mode", colorblind_mode)
	_save_keybindings(_current_keybindings())
	_file.save(PATH)

func _default_keybindings() -> Dictionary:
	var out := {}
	for action in REBINDABLE_ACTIONS:
		var events := InputMap.action_get_events(action) if InputMap.has_action(action) else []
		var scancodes: Array[int] = []
		for ev in events:
			if ev is InputEventKey:
				scancodes.append(ev.keycode)
		out[action] = scancodes
	return out

func _current_keybindings() -> Dictionary:
	var out := {}
	for action in REBINDABLE_ACTIONS:
		var scancodes: Array[int] = []
		if InputMap.has_action(action):
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey:
					scancodes.append(ev.keycode)
		out[action] = scancodes
	return out

func _save_keybindings(bindings: Dictionary):
	for action in REBINDABLE_ACTIONS:
		var scancodes: Array = bindings.get(action, [])
		_file.set_value("bindings", action, scancodes)

func _load_keybindings():
	for action in REBINDABLE_ACTIONS:
		if not _file.has_section_key("bindings", action):
			continue
		var stored: Array = _file.get_value("bindings", action, [])
		if stored.is_empty():
			continue
		if not InputMap.has_action(action):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		for code in stored:
			var ke := InputEventKey.new()
			ke.keycode = code as Key
			InputMap.action_add_event(action, ke)

func set_keybinding(action: String, scancodes: Array[int]):
	if not action in REBINDABLE_ACTIONS:
		return
	if not InputMap.has_action(action):
		return
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	for code in scancodes:
		var ke := InputEventKey.new()
		ke.keycode = code as Key
		InputMap.action_add_event(action, ke)
	save()
