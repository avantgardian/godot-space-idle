extends Button

signal pause_toggled

var _overlay: ColorRect

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	name = "PauseButton"
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -96.0
	offset_top = -46.0
	offset_right = -16.0
	offset_bottom = -16.0
	text = "Pause"

	add_theme_font_size_override("font_size", 14)

	_overlay = ColorRect.new()
	_overlay.name = "PauseOverlay"
	_overlay.anchor_left = 0.0
	_overlay.anchor_top = 0.0
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.3)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	_overlay.hide()
	get_parent().call_deferred("add_child", _overlay)

	pressed.connect(_on_pressed)

func _on_pressed():
	pause_toggled.emit()

func set_pause_state(paused: bool):
	text = "Play" if paused else "Pause"

func set_overlay_visible(flag: bool):
	_overlay.visible = flag
