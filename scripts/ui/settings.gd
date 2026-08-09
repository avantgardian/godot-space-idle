class_name SettingsScreen
extends Control

const PAL := preload("res://scripts/util/tron_palette.gd")
const FONT_MONO := preload("res://resources/fonts/ShareTechMono-Regular.ttf")
const _SM := preload("res://scripts/util/settings_manager.gd")

var _settings: SettingsManager
var _rebind_popup: Control
var _rebind_action: String = ""


func _ready():
	var game_theme := load("res://resources/game_theme.tres") as Theme
	self.theme = game_theme
	_settings = _SM.new()
	_setup_background()
	_setup_rebind_popup()
	_build_ui()


func _setup_background():
	var bg := ColorRect.new()
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = PAL.BG
	add_child(bg)

	var grid := ColorRect.new()
	grid.anchor_left = 0.0
	grid.anchor_top = 0.0
	grid.anchor_right = 1.0
	grid.anchor_bottom = 1.0
	var grid_mat := ShaderMaterial.new()
	grid_mat.shader = preload("res://shaders/world/menu_grid.gdshader")
	grid_mat.set_shader_parameter("line_color", Color(0.18, 0.55, 1.0, 0.08))
	grid_mat.set_shader_parameter("cell_size", 50.0)
	grid_mat.set_shader_parameter("line_width", 1.0)
	grid.material = grid_mat
	grid.color = Color(0, 0, 0, 0)
	grid.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(grid)


func _setup_rebind_popup():
	_rebind_popup = Control.new()
	_rebind_popup.name = "RebindPopup"
	_rebind_popup.anchor_left = 0.0
	_rebind_popup.anchor_top = 0.0
	_rebind_popup.anchor_right = 1.0
	_rebind_popup.anchor_bottom = 1.0
	_rebind_popup.hide()
	add_child(_rebind_popup)

	var popup_bg := ColorRect.new()
	popup_bg.anchor_left = 0.0
	popup_bg.anchor_top = 0.0
	popup_bg.anchor_right = 1.0
	popup_bg.anchor_bottom = 1.0
	popup_bg.color = Color(0, 0, 0, 0.7)
	_rebind_popup.add_child(popup_bg)

	var popup_label := Label.new()
	popup_label.name = "RebindLabel"
	popup_label.anchor_left = 0.5
	popup_label.anchor_top = 0.5
	popup_label.anchor_right = 0.5
	popup_label.anchor_bottom = 0.5
	popup_label.offset_left = -200
	popup_label.offset_top = -50
	popup_label.offset_right = 200
	popup_label.offset_bottom = 50
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 24)
	popup_label.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	_rebind_popup.add_child(popup_label)


func _build_ui():
	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	margin.add_child(main_vbox)

	# ---- Header ----
	var header := CenterContainer.new()
	header.add_theme_constant_override("margin_top", 30)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	title.add_theme_color_override("font_outline_color", PAL.HULL_GLOW)
	title.add_theme_constant_override("outline_size", 3)
	header.add_child(title)
	main_vbox.add_child(header)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(300, 1)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	underline.color = Color(PAL.HULL_LINE.r, PAL.HULL_LINE.g, PAL.HULL_LINE.b, 0.4)
	main_vbox.add_child(underline)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)

	# ---- Scrollable content ----
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	main_vbox.add_child(scroll)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_spacer)

	var sections := VBoxContainer.new()
	sections.custom_minimum_size = Vector2(520, 0)
	sections.add_theme_constant_override("separation", 16)
	row.add_child(sections)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_spacer)

	# ---- Key bindings ----
	sections.add_child(_section_header("Key Bindings"))
	var keys_container := _margin_child(_build_keybindings_section())
	sections.add_child(keys_container)

	# ---- Display ----
	sections.add_child(_section_header("Display"))

	var fullscreen_cb := _checkbox(
		"Fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen_cb.toggled.connect(
		func(on: bool):
			if on:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	sections.add_child(_margin_child(fullscreen_cb))

	var vsync_cb := _checkbox(
		"VSync", DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	)
	vsync_cb.toggled.connect(
		func(on: bool):
			var mode := DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(mode)
	)
	sections.add_child(_margin_child(vsync_cb))

	# ---- Accessibility ----
	sections.add_child(_section_header("Accessibility"))

	var motion_cb := _checkbox("Reduced Motion", _settings.reduced_motion)
	motion_cb.toggled.connect(
		func(on: bool):
			_settings.reduced_motion = on
			_settings.save()
	)
	sections.add_child(_margin_child(motion_cb))

	var shake_cb := _checkbox("Screen Shake", _settings.screen_shake)
	shake_cb.toggled.connect(
		func(on: bool):
			_settings.screen_shake = on
			_settings.save()
	)
	sections.add_child(_margin_child(shake_cb))

	var cb_option := OptionButton.new()
	cb_option.add_item("Off", 0)
	cb_option.add_item("Protanopia", 1)
	cb_option.add_item("Deuteranopia", 2)
	cb_option.add_item("Tritanopia", 3)
	cb_option.selected = _settings.colorblind_mode
	cb_option.item_selected.connect(
		func(idx: int):
			_settings.colorblind_mode = idx
			_settings.save()
	)
	sections.add_child(_margin_child(_labelled_control("Colorblind Preset", cb_option)))

	# ---- Footer ----
	var footer := CenterContainer.new()
	footer.add_theme_constant_override("margin_top", 20)
	footer.add_theme_constant_override("margin_bottom", 30)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(260, 48)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_on_back)
	footer.add_child(back_btn)
	main_vbox.add_child(footer)


func _build_keybindings_section() -> VBoxContainer:
	var keys_vbox := VBoxContainer.new()
	keys_vbox.add_theme_constant_override("separation", 6)

	for action in SettingsManager.REBINDABLE_ACTIONS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var lbl := Label.new()
		lbl.text = action.capitalize().replace("_", " ")
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", PAL.HULL_LINE)
		lbl.custom_minimum_size = Vector2(200, 0)
		hbox.add_child(lbl)

		var key_lbl := Label.new()
		key_lbl.name = "KeyLabel_%s" % action
		key_lbl.text = _key_label_text(action)
		key_lbl.add_theme_font_override("font", FONT_MONO)
		key_lbl.add_theme_font_size_override("font_size", 14)
		key_lbl.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
		key_lbl.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(key_lbl)

		var rebind_btn := Button.new()
		rebind_btn.text = "Rebind"
		rebind_btn.custom_minimum_size = Vector2(80, 30)
		rebind_btn.add_theme_font_size_override("font_size", 12)
		rebind_btn.pressed.connect(_on_rebind_pressed.bind(action))
		hbox.add_child(rebind_btn)

		keys_vbox.add_child(hbox)

	return keys_vbox


func _key_label_text(action: String) -> String:
	var keys: Array[String] = []
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				keys.append(OS.get_keycode_string(ev.keycode))
	if keys.is_empty():
		return "(none)"
	return ", ".join(keys)


func _section_header(title_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	lbl.add_theme_color_override("font_outline_color", PAL.HULL_GLOW)
	lbl.add_theme_constant_override("outline_size", 2)
	return lbl


func _checkbox(label_text: String, checked: bool) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = checked
	cb.add_theme_font_size_override("font_size", 14)
	cb.add_theme_color_override("font_color", PAL.HULL_LINE)
	return cb


func _labelled_control(label_text: String, ctrl: Control) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", PAL.HULL_LINE)
	lbl.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(lbl)
	hbox.add_child(ctrl)
	return hbox


func _margin_child(child: Control) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 24)
	mc.add_theme_constant_override("margin_top", 4)
	mc.add_child(child)
	return mc


func _on_rebind_pressed(action: String):
	_rebind_action = action
	_rebind_popup.show()
	_rebind_popup.get_node("RebindLabel").text = (
		"Press a key for: " + action.capitalize().replace("_", " ")
	)


func _input(event):
	if not _rebind_popup.visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_rebind_popup.hide()
			_rebind_action = ""
			return
		_apply_rebind(event.keycode)
		_rebind_popup.hide()


func _apply_rebind(keycode: int):
	if _rebind_action.is_empty():
		return
	_settings.set_keybinding(_rebind_action, [keycode])
	var key_node := find_child("KeyLabel_%s" % _rebind_action, true, false)
	if key_node is Label:
		key_node.text = OS.get_keycode_string(keycode)
	_rebind_action = ""


func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
