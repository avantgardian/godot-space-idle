class_name SunPopup
extends Panel

const PAL := preload("res://scripts/util/tron_palette.gd")
const DU := preload("res://scripts/util/draw_utils.gd")
const FONT_MONO := preload("res://resources/fonts/ShareTechMono-Regular.ttf")

var _controller: Node
var _camera: Camera2D
var _sun_node: Sprite2D
var reduced_motion: bool = false
var _mass_val: Label

func show_for_sun(controller: Node, camera: Camera2D, sun_node: Sprite2D, star_type_label: String):
	_controller = controller
	_camera = camera
	_sun_node = sun_node

	mouse_filter = MOUSE_FILTER_IGNORE
	theme = load("res://resources/game_theme.tres") as Theme

	var stripe := ColorRect.new()
	stripe.name = "AccentStripe"
	stripe.color = DU.modulate_alpha(PAL.ACCENT, 0.9)
	stripe.anchor_left = 0.0
	stripe.anchor_top = 0.0
	stripe.anchor_right = 0.0
	stripe.anchor_bottom = 1.0
	stripe.offset_left = 4.0
	stripe.offset_top = 8.0
	stripe.offset_right = 7.0
	stripe.offset_bottom = -8.0
	add_child(stripe)

	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var name_text := "Sun"
	if star_type_label != "":
		name_text += " [" + star_type_label + "]"
	var name_label := Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	vbox.add_child(name_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep.color = DU.modulate_alpha(PAL.HULL_LINE, 0.3)
	vbox.add_child(sep)

	var mass_hbox := HBoxContainer.new()
	mass_hbox.add_theme_constant_override("separation", 8)
	var mass_lbl := Label.new()
	mass_lbl.text = "Mass"
	mass_lbl.add_theme_font_size_override("font_size", 11)
	mass_lbl.add_theme_color_override("font_color", DU.modulate_alpha(PAL.HULL_LINE, 0.7))
	mass_lbl.custom_minimum_size = Vector2(48, 0)
	mass_hbox.add_child(mass_lbl)
	_mass_val = Label.new()
	_mass_val.add_theme_font_override("font", FONT_MONO)
	_mass_val.add_theme_font_size_override("font_size", 11)
	_mass_val.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	mass_hbox.add_child(_mass_val)
	vbox.add_child(mass_hbox)

	size = Vector2(220, 100)

	modulate = Color(1, 1, 1, 0)
	if reduced_motion:
		modulate = Color(1, 1, 1, 1)
	else:
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _process(_delta):
	if not _controller or not _camera or not _sun_node:
		return
	if not is_instance_valid(_controller) or not is_instance_valid(_sun_node):
		close()
		return

	_mass_val.text = "%.4f  Msun" % _controller.sun_mass

	var viewport_size := get_viewport_rect().size
	var screen_pos: Vector2 = _camera.get_canvas_transform() * _sun_node.position
	var ps := size
	var sun_screen_r: float = max(60.0 * _camera.zoom.x, 30.0)
	position = screen_pos + Vector2(sun_screen_r + 16, -ps.y - 36)
	position.x = clamp(position.x, 10, viewport_size.x - ps.x - 10)
	position.y = clamp(position.y, 10, viewport_size.y - ps.y - 10)

func close():
	if reduced_motion:
		queue_free()
	else:
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_callback(queue_free)
