class_name SunPopup
extends Panel

const PAL: GDScript = preload("res://scripts/util/tron_palette.gd")
const DU: GDScript = preload("res://scripts/util/draw_utils.gd")
const FONT_MONO: Font = preload("res://resources/fonts/ShareTechMono-Regular.ttf")

var reduced_motion: bool = false
var _controller: Node
var _camera: Camera2D
var _sun_node: Sprite2D
var _mass_val: Label


func show_for_sun(
	controller: Node, camera: Camera2D, sun_node: Sprite2D, star_type_label: String
) -> void:
	_controller = controller
	_camera = camera
	_sun_node = sun_node

	mouse_filter = MOUSE_FILTER_IGNORE
	theme = load("res://resources/game_theme.tres") as Theme

	var stripe: ColorRect = ColorRect.new()
	stripe.name = "AccentStripe"
	@warning_ignore("unsafe_method_access", "unsafe_property_access")
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

	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var name_text: String = "Sun"
	if star_type_label != "":
		name_text += " [" + star_type_label + "]"
	var name_label: Label = Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 18)
	@warning_ignore("unsafe_property_access")
	name_label.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	vbox.add_child(name_label)

	var sep: ColorRect = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	@warning_ignore("unsafe_method_access", "unsafe_property_access")
	sep.color = DU.modulate_alpha(PAL.HULL_LINE, 0.3)
	vbox.add_child(sep)

	var mass_hbox: HBoxContainer = HBoxContainer.new()
	mass_hbox.add_theme_constant_override("separation", 8)
	var mass_lbl: Label = Label.new()
	mass_lbl.text = "Mass"
	mass_lbl.add_theme_font_size_override("font_size", 11)
	@warning_ignore("unsafe_method_access", "unsafe_property_access", "unsafe_call_argument")
	mass_lbl.add_theme_color_override("font_color", DU.modulate_alpha(PAL.HULL_LINE, 0.7))
	mass_lbl.custom_minimum_size = Vector2(48, 0)
	mass_hbox.add_child(mass_lbl)
	_mass_val = Label.new()
	_mass_val.add_theme_font_override("font", FONT_MONO)
	_mass_val.add_theme_font_size_override("font_size", 11)
	@warning_ignore("unsafe_property_access")
	_mass_val.add_theme_color_override("font_color", PAL.HULL_BRIGHT)
	mass_hbox.add_child(_mass_val)
	vbox.add_child(mass_hbox)

	size = Vector2(220, 100)

	modulate = Color(1, 1, 1, 0)
	if reduced_motion:
		modulate = Color(1, 1, 1, 1)
	else:
		var tween: Tween = create_tween()
		(
			tween
			. tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)
			. set_ease(Tween.EASE_OUT)
			. set_trans(Tween.TRANS_CUBIC)
		)


func _process(_delta: float) -> void:
	if not _controller or not _camera or not _sun_node:
		return
	if not is_instance_valid(_controller) or not is_instance_valid(_sun_node):
		close()
		return

	@warning_ignore("unsafe_property_access")
	_mass_val.text = "%.4f  Msun" % _controller.sun_mass

	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_pos: Vector2 = _camera.get_canvas_transform() * _sun_node.position
	var ps: Vector2 = size
	var sun_screen_r: float = max(60.0 * _camera.zoom.x, 30.0)
	position = screen_pos + Vector2(sun_screen_r + 16, -ps.y - 36)
	position.x = clamp(position.x, 10, viewport_size.x - ps.x - 10)
	position.y = clamp(position.y, 10, viewport_size.y - ps.y - 10)


func close() -> void:
	if reduced_motion:
		queue_free()
	else:
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
		tween.tween_callback(queue_free)
