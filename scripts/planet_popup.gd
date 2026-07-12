class_name PlanetPopup
extends Panel

var _planet_node: Node2D
var _camera: Camera2D
var _popup_labels: Dictionary = {}

func show_for_planet(planet_node: Node2D, camera: Camera2D):
	_planet_node = planet_node
	_camera = camera

	mouse_filter = MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.1, 0.88)
	sb.border_color = planet_node.planet_color
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	add_theme_stylebox_override("panel", sb)

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

	var name_label := Label.new()
	name_label.text = planet_node.planet_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0, 1.0))
	vbox.add_child(name_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep.color = Color(0.3, 0.4, 0.6, 0.25)
	vbox.add_child(sep)

	var fields := [
		{ key = "mass",   label = "Mass",   fmt = "%s  M☉" },
		{ key = "speed",  label = "Speed",  fmt = "%.1f  km/s" },
		{ key = "radius", label = "Orbit",  fmt = "%.0f  u" },
		{ key = "period", label = "Period", fmt = "%.0f  s" },
	]
	for f in fields:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		var lbl := Label.new()
		lbl.text = f.label
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7, 1.0))
		lbl.custom_minimum_size = Vector2(48, 0)
		hbox.add_child(lbl)
		var val := Label.new()
		val.add_theme_font_size_override("font_size", 11)
		val.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1.0))
		hbox.add_child(val)
		_popup_labels[f.key] = val
		vbox.add_child(hbox)

	size = Vector2(280, 150)

	modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _process(_delta):
	if not _planet_node or not _camera:
		return
	if not is_instance_valid(_planet_node):
		close()
		return

	var viewport_size := get_viewport_rect().size

	_popup_labels.mass.text = "%s  M☉" % str(_planet_node.mass)
	_popup_labels.speed.text = "%.1f  km/s" % _planet_node.planet_speed
	_popup_labels.radius.text = "%.0f  u" % _planet_node.orbit_radius
	_popup_labels.period.text = "%.0f  s" % _planet_node.orbit_period

	var screen_pos: Vector2 = _camera.get_canvas_transform() * _planet_node.position
	var ps := size

	position = screen_pos + Vector2(24, -ps.y - 36)
	position.x = clamp(position.x, 10, viewport_size.x - ps.x - 10)
	position.y = clamp(position.y, 10, viewport_size.y - ps.y - 10)

func close():
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(queue_free)
