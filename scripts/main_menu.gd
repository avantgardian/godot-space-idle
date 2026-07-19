extends Control

const PAL := preload("res://scripts/tron_palette.gd")

func _ready():
	var game_theme := load("res://resources/game_theme.tres") as Theme
	self.theme = game_theme

	var title := $CenterContainer/MenuContainer/Title as Label
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	title.add_theme_color_override("font_outline_color", PAL.HULL_GLOW)
	title.add_theme_constant_override("outline_size", 4)

	var title_underline := ColorRect.new()
	title_underline.name = "TitleUnderline"
	title_underline.custom_minimum_size = Vector2(420, 2)
	title_underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_underline.color = Color(PAL.HULL_LINE.r, PAL.HULL_LINE.g, PAL.HULL_LINE.b, 0.5)
	$CenterContainer/MenuContainer.add_child(title_underline)
	$CenterContainer/MenuContainer.move_child(title_underline, title.get_index() + 1)

	$CenterContainer/MenuContainer.add_theme_constant_override("separation", 14)

	var buttons: Array[Button] = [
		$CenterContainer/MenuContainer/SandboxBtn as Button,
		$CenterContainer/MenuContainer/ProgressionBtn as Button,
		$CenterContainer/MenuContainer/SettingsBtn as Button,
		$CenterContainer/MenuContainer/QuitBtn as Button,
	]

	for btn in buttons:
		btn.custom_minimum_size = Vector2(320, 52)

	$CenterContainer/MenuContainer/SandboxBtn.pressed.connect(_on_sandbox_pressed)
	$CenterContainer/MenuContainer/ProgressionBtn.pressed.connect(_on_progression_pressed)
	$CenterContainer/MenuContainer/QuitBtn.pressed.connect(_on_quit_pressed)

func _on_sandbox_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_progression_pressed():
	get_tree().change_scene_to_file("res://scenes/progression.tscn")

func _on_quit_pressed():
	get_tree().quit()