extends Button

signal pause_toggled


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

	pressed.connect(_on_pressed)


func _on_pressed():
	pause_toggled.emit()


func set_pause_state(paused: bool):
	text = "Play" if paused else "Pause"
