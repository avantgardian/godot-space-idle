extends Control

func _ready():
	var game_theme := load("res://resources/game_theme.tres") as Theme
	self.theme = game_theme

	var title := $CenterContainer/MenuContainer/Title as Label
	title.add_theme_font_size_override("font_size", 48)

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
