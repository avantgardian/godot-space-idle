class_name PauseMenu
extends Panel

signal resume_pressed
signal save_pressed
signal load_pressed
signal exit_to_menu_pressed

const PAL := preload("res://scripts/util/tron_palette.gd")
const FONT_BOLD := preload("res://resources/fonts/Orbitron-Bold.ttf")

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_IGNORE

	theme = load("res://resources/game_theme.tres") as Theme

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	_setup_overlay()
	_setup_menu()

	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func _setup_overlay():
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlay)

func _setup_menu():
	var center := CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_top = 0.0
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_override("font", FONT_BOLD)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	title.add_theme_color_override("font_outline_color", PAL.HULL_GLOW)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	vbox.add_child(spacer)

	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(260.0, 44.0)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.custom_minimum_size = Vector2(260.0, 44.0)
	save_btn.disabled = true
	save_btn.pressed.connect(_on_save)
	vbox.add_child(save_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(260.0, 44.0)
	load_btn.disabled = true
	load_btn.pressed.connect(_on_load)
	vbox.add_child(load_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Exit to Main Menu"
	exit_btn.custom_minimum_size = Vector2(260.0, 44.0)
	exit_btn.pressed.connect(_on_exit_to_menu)
	vbox.add_child(exit_btn)

func _on_resume():
	emit_signal("resume_pressed")

func _on_save():
	emit_signal("save_pressed")

func _on_load():
	emit_signal("load_pressed")

func _on_exit_to_menu():
	emit_signal("exit_to_menu_pressed")

func close():
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(queue_free)
