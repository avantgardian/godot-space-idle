extends Control

func _ready():
	var title := $CenterContainer/MenuContainer/Title as Label
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0, 1.0))

	$CenterContainer/MenuContainer.add_theme_constant_override("separation", 14)

	var buttons: Array[Button] = [
		$CenterContainer/MenuContainer/SandboxBtn as Button,
		$CenterContainer/MenuContainer/ProgressionBtn as Button,
		$CenterContainer/MenuContainer/SettingsBtn as Button,
		$CenterContainer/MenuContainer/QuitBtn as Button,
	]

	for btn in buttons:
		_style_button(btn)

	$CenterContainer/MenuContainer/SandboxBtn.pressed.connect(_on_sandbox_pressed)
	$CenterContainer/MenuContainer/QuitBtn.pressed.connect(_on_quit_pressed)

func _style_button(btn: Button):
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.4, 0.5))
	btn.custom_minimum_size = Vector2(320, 52)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.05, 0.05, 0.15, 0.7)
	sb_normal.border_color = Color(0.3, 0.4, 0.6, 0.8)
	sb_normal.border_width_left = 2
	sb_normal.border_width_top = 2
	sb_normal.border_width_right = 2
	sb_normal.border_width_bottom = 2
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.content_margin_left = 16
	sb_normal.content_margin_right = 16
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.12, 0.15, 0.3, 0.8)
	sb_hover.border_color = Color(0.5, 0.6, 0.9, 1.0)
	sb_hover.border_width_left = 2
	sb_hover.border_width_top = 2
	sb_hover.border_width_right = 2
	sb_hover.border_width_bottom = 2
	sb_hover.corner_radius_top_left = 6
	sb_hover.corner_radius_top_right = 6
	sb_hover.corner_radius_bottom_right = 6
	sb_hover.corner_radius_bottom_left = 6
	sb_hover.content_margin_left = 16
	sb_hover.content_margin_right = 16
	sb_hover.content_margin_top = 8
	sb_hover.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.08, 0.1, 0.25, 0.8)
	sb_pressed.border_color = Color(0.6, 0.7, 1.0, 1.0)
	sb_pressed.border_width_left = 2
	sb_pressed.border_width_top = 2
	sb_pressed.border_width_right = 2
	sb_pressed.border_width_bottom = 2
	sb_pressed.corner_radius_top_left = 6
	sb_pressed.corner_radius_top_right = 6
	sb_pressed.corner_radius_bottom_right = 6
	sb_pressed.corner_radius_bottom_left = 6
	sb_pressed.content_margin_left = 16
	sb_pressed.content_margin_right = 16
	sb_pressed.content_margin_top = 8
	sb_pressed.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.03, 0.03, 0.08, 0.4)
	sb_disabled.border_color = Color(0.15, 0.15, 0.25, 0.4)
	sb_disabled.border_width_left = 2
	sb_disabled.border_width_top = 2
	sb_disabled.border_width_right = 2
	sb_disabled.border_width_bottom = 2
	sb_disabled.corner_radius_top_left = 6
	sb_disabled.corner_radius_top_right = 6
	sb_disabled.corner_radius_bottom_right = 6
	sb_disabled.corner_radius_bottom_left = 6
	sb_disabled.content_margin_left = 16
	sb_disabled.content_margin_right = 16
	sb_disabled.content_margin_top = 8
	sb_disabled.content_margin_bottom = 8
	btn.add_theme_stylebox_override("disabled", sb_disabled)

func _on_sandbox_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
