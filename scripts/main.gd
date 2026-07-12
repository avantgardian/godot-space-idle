extends Node2D

@export var star_seed: int = 42

const SCREEN_SIZE := Vector2(1920, 1080)
const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

const PLANET_SPEEDS := [47.4, 35.0, 29.8, 24.1, 13.1, 9.7, 6.8, 5.4]

var sun_mass: float = 1.0
var _mass_label: Label
var _asteroids: Array[Node2D]
var _asteroid_spawn_timer: float = 5.0
var _planet_data: Array[Dictionary]
const _ASTEROID_SCRIPT := preload("res://scripts/asteroid.gd")
const PLANET_NAMES := ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
const PLANET_COLORS := [
	Color(0.7, 0.7, 0.7),
	Color(0.95, 0.85, 0.5),
	Color(0.3, 0.6, 1.0),
	Color(0.85, 0.35, 0.15),
	Color(0.85, 0.6, 0.3),
	Color(0.8, 0.7, 0.4),
	Color(0.4, 0.7, 0.9),
	Color(0.2, 0.3, 0.85),
]
func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	$StarField.generate(star_seed, $Camera2D.min_zoom)
	$Sun.generate()
	_mass_label = $UI/MassLabel as Label
	_planet_data = [
		{ node = $Mercury, color0 = Color(1, 1, 1, 0.0), color1 = Color(1, 1, 1, 0.5), cf = 0.6, cc = Color(1, 0.9, 0.6, 0.5), cw = 2.0, cs = 48, ct = 0.8 },
		{ node = $Venus, color0 = Color(1, 0.9, 0.6, 0.0), color1 = Color(1, 0.9, 0.6, 0.4), cf = 0.8, cc = Color(1, 0.8, 0.4, 0.6), cw = 3.0, cs = 64, ct = 1.2 },
		{ node = $Earth, color0 = Color(0.3, 0.6, 1.0, 0.0), color1 = Color(0.3, 0.6, 1.0, 0.4), cf = 1.0, cc = Color(0.3, 0.7, 1.0, 0.7), cw = 3.5, cs = 72, ct = 1.5 },
		{ node = $Mars, color0 = Color(0, 0, 0, 0.0), color1 = Color(1.0, 0.6, 0.1, 0.4), cf = 0.7, cc = Color(0.9, 0.4, 0.15, 0.5), cw = 2.0, cs = 40, ct = 0.9 },
		{ node = $Jupiter, color0 = Color(0.85, 0.6, 0.3, 0.0), color1 = Color(0.85, 0.6, 0.3, 0.4), cf = 2.0, cc = Color(0.85, 0.6, 0.3, 0.9), cw = 6.0, cs = 96, ct = 2.5 },
		{ node = $Saturn, color0 = Color(0.8, 0.7, 0.4, 0.0), color1 = Color(0.8, 0.7, 0.4, 0.4), cf = 1.8, cc = Color(0.8, 0.7, 0.4, 0.8), cw = 5.0, cs = 88, ct = 2.2 },
		{ node = $Uranus, color0 = Color(0.4, 0.7, 0.9, 0.0), color1 = Color(0.4, 0.7, 0.9, 0.4), cf = 1.2, cc = Color(0.4, 0.7, 0.9, 0.6), cw = 3.0, cs = 64, ct = 1.6 },
		{ node = $Neptune, color0 = Color(0.2, 0.3, 0.85, 0.0), color1 = Color(0.2, 0.3, 0.85, 0.4), cf = 1.3, cc = Color(0.2, 0.3, 0.85, 0.6), cw = 3.0, cs = 66, ct = 1.7 },
	]
	for p in _planet_data:
		p.node.collided_with_sun.connect(_on_planet_collided.bind(p))
		p.node.setup_trail(p.color0, p.color1)
		p.initial_mass = p.node.mass
		p.destroyed_by = ""
	_setup_pause_button()
	_setup_post_process()

func _setup_pause_button():
	var btn := Button.new()
	btn.name = "PauseButton"
	btn.anchor_left = 1.0
	btn.anchor_top = 1.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -96.0
	btn.offset_top = -46.0
	btn.offset_right = -16.0
	btn.offset_bottom = -16.0
	btn.text = "Pause"
	btn.pressed.connect(_toggle_pause)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	sb.border_color = Color(0.5, 0.6, 0.8, 0.9)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.15, 0.2, 0.35, 0.6)
	sb_hover.border_color = Color(0.7, 0.8, 1.0, 1.0)
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left = 4
	sb_hover.corner_radius_top_right = 4
	sb_hover.corner_radius_bottom_right = 4
	sb_hover.corner_radius_bottom_left = 4
	sb_hover.content_margin_left = 12
	sb_hover.content_margin_right = 12
	sb_hover.content_margin_top = 4
	sb_hover.content_margin_bottom = 4
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 14)

	$UI.add_child(btn)

	var overlay := ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.3)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.hide()
	$UI.add_child(overlay)

var _paused := false

func _toggle_pause():
	_paused = not _paused
	Engine.time_scale = 0.0 if _paused else 1.0
	var btn := $UI/PauseButton as Button
	btn.text = "Play" if _paused else "Pause"
	var overlay := $UI/PauseOverlay as ColorRect
	overlay.visible = _paused

func _setup_post_process():
	var pp_layer := CanvasLayer.new()
	pp_layer.name = "PostProcessLayer"
	pp_layer.layer = 1
	add_child(pp_layer)

	($UI as CanvasLayer).layer = 2

	var cr := ColorRect.new()
	cr.name = "PostProcess"
	cr.anchor_left = 0.0
	cr.anchor_top = 0.0
	cr.anchor_right = 1.0
	cr.anchor_bottom = 1.0
	cr.color = Color(1, 1, 1, 1)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pp_layer.add_child(cr)

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/post_process.gdshader")
	cr.material = mat
	_post_process_mat = mat

func _trigger_impact_effects():
	_ca_impact = min(_ca_impact + 0.008, 0.015)
	$Camera2D.trigger_shake(12.5)

func _body_name(body: Node2D) -> String:
	var idx := _find_planet_idx(body)
	return PLANET_NAMES[idx] if idx >= 0 else "Asteroid"

func _collision_msg(victim: Node2D, absorber: Node2D) -> String:
	if _find_planet_idx(victim) < 0 or _find_planet_idx(absorber) < 0:
		return _body_name(victim) + " collided with " + _body_name(absorber)
	return _body_name(victim) + " was destroyed by " + _body_name(absorber)

func _show_planet_popup(planet_node: Node2D):
	_hide_planet_popup()
	var idx := _find_planet_idx(planet_node)
	if idx < 0:
		return
	var color: Color = PLANET_COLORS[idx]

	var panel := Panel.new()
	panel.name = "PlanetPopup"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.1, 0.88)
	sb.border_color = color
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.text = PLANET_NAMES[idx]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0, 1.0))
	vbox.add_child(name_label)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sep.color = Color(0.3, 0.4, 0.6, 0.25)
	vbox.add_child(sep)

	_popup_labels = {}
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

	$UI.add_child(panel)
	_planet_popup = panel
	panel.size = Vector2(280, 150)

	panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func _update_planet_popup():
	if not _planet_popup or not $Camera2D.is_following():
		return
	var node = $Camera2D.get_follow_target()
	if not node:
		return
	_popup_labels.mass.text = "%s  M☉" % str(node.mass)
	var sidx := _find_planet_idx(node)
	_popup_labels.speed.text = "%.1f  km/s" % (PLANET_SPEEDS[sidx] if sidx >= 0 else 0.0)
	_popup_labels.radius.text = "%.0f  u" % node.orbit_radius
	_popup_labels.period.text = "%.0f  s" % node.orbit_period

	var camera := $Camera2D as Camera2D
	var screen_pos: Vector2 = camera.get_canvas_transform() * node.position
	var panel: Panel = _planet_popup
	var ps := panel.size

	panel.position = screen_pos + Vector2(24, -ps.y - 36)
	panel.position.x = clamp(panel.position.x, 10, SCREEN_SIZE.x - ps.x - 10)
	panel.position.y = clamp(panel.position.y, 10, SCREEN_SIZE.y - ps.y - 10)

func _hide_planet_popup():
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	var panel := _planet_popup
	_planet_popup = null
	_popup_labels = {}
	var tween := create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_callback(panel.queue_free)


var _planet_popup: Panel
var _popup_labels: Dictionary

var _post_process_mat: ShaderMaterial
var _ca_impact: float = 0.0

func _process(delta):
	$Sun.mass = sun_mass

	for p in _planet_data:
		p.node.sun_mass = sun_mass

	_check_body_collisions()

	var planet_data: Array[Dictionary] = []
	for p in _planet_data:
		if not p.node._dead:
			planet_data.append({ pos = p.node.position, mass = p.node.mass })

	for i in range(_asteroids.size() - 1, -1, -1):
		var a := _asteroids[i] as Node2D
		if not a.is_alive():
			a.queue_free()
			_asteroids.remove_at(i)
		else:
			a.sun_mass = sun_mass
			a._planets = planet_data

	_asteroid_spawn_timer -= delta
	if _asteroid_spawn_timer <= 0.0 and _asteroids.size() < 3:
		_spawn_asteroid()
		_asteroid_spawn_timer = randf_range(35.0, 55.0)

	if _mass_label:
		_mass_label.text = "M☉ = %.7f" % sun_mass

	if _ca_impact > 0.0:
		_ca_impact = max(_ca_impact - 0.02 * delta, 0.0)
		if _post_process_mat:
			_post_process_mat.set_shader_parameter("u_ca_impact", _ca_impact)

	if _planet_popup and $Camera2D.is_following():
		_update_planet_popup()
	elif _planet_popup and not $Camera2D.is_following():
		_hide_planet_popup()

	$StarField.update_parallax($Camera2D.position, $Camera2D.zoom.x)
	$StarField.set_blur($Camera2D.get_blur_amount())

func _check_planet_click(screen_pos: Vector2) -> Dictionary:
	var closest: Dictionary
	var found := false
	var closest_dist := INF
	for p in _planet_data:
		if p.node._dead:
			continue
		var planet_screen: Vector2 = $Camera2D.get_canvas_transform() * p.node.position
		var d := planet_screen.distance_to(screen_pos)
		var hit_r: float = max(p.node.collision_radius * $Camera2D.zoom.x, 12.0)
		if d < hit_r and d < closest_dist:
			closest = p
			closest_dist = d
			found = true
	return closest if found else {}


func _find_planet_idx(node: Node2D) -> int:
	for i in _planet_data.size():
		if _planet_data[i].node == node:
			return i
	return -1

func _on_planet_collided(p: Dictionary):
	sun_mass += p.node.mass
	p.destroyed_by = "Sun"
	$Sun.flash(p.cf)
	$ImpactFX.spawn_ring(p.cc, p.cw, p.cs, p.ct)
	_trigger_impact_effects()
	var p_idx := _find_planet_idx(p.node)
	$UI/EventLog.log_message(PLANET_NAMES[p_idx] + " collided with the Sun")

func _spawn_asteroid():
	var a := Node2D.new()
	a.set_script(_ASTEROID_SCRIPT)
	a.sun_mass = sun_mass
	a.collided_with_sun.connect(_on_asteroid_collided.bind(a))
	a.spawn()
	add_child(a)
	_asteroids.append(a)

func _on_asteroid_collided(ast: Node2D):
	sun_mass += ast.mass
	$Sun.flash(0.2)
	$ImpactFX.spawn_ring(Color(1, 0.7, 0.3, 0.3), 1.5, 24, 0.4)
	_trigger_impact_effects()
	$UI/EventLog.log_message("Asteroid collided with the Sun")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = $Camera2D.get_canvas_transform() * $Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.button_index == MOUSE_BUTTON_LEFT and on_sun:
			sun_mass += 0.01
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			var clicked := _check_planet_click(event.position)
			if not clicked.is_empty():
				$Camera2D.follow_node(clicked.node)
				_show_planet_popup(clicked.node)
				return

		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			$Camera2D.start_drag(event.position)
			_hide_planet_popup()

	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			$Camera2D.end_drag()

	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		$Camera2D.update_drag(event.position)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_MINUS:
			pass
		elif event.keycode == KEY_L:
			_spawn_asteroid()


func _check_body_collisions():
	var all_bodies: Array[Node2D] = []

	for p in _planet_data:
		if not p.node._dead:
			all_bodies.append(p.node)

	for a in _asteroids:
		if a.is_alive():
			all_bodies.append(a)

	for i in all_bodies.size():
		for j in range(i + 1, all_bodies.size()):
			var a := all_bodies[i]
			var b := all_bodies[j]
			if not _is_body_alive(a) or not _is_body_alive(b):
				continue
			var dist := a.position.distance_to(b.position)
			if dist < a.collision_radius + b.collision_radius:
				var contact_r: float = a.collision_radius + b.collision_radius
				if a.mass >= b.mass:
					var total: float = a.mass + b.mass
					a._vel = (a._vel * a.mass + b._vel * b.mass) / total
					a.mass = total
					var b_idx := _find_planet_idx(b)
					if b_idx >= 0:
						var a_idx := _find_planet_idx(a)
						_planet_data[b_idx].destroyed_by = PLANET_NAMES[a_idx] if a_idx >= 0 else "???"
					_disable_body(b)
					$ImpactFX.spawn_glow(a.position.lerp(b.position, 0.5), b.mass, contact_r)
					_trigger_impact_effects()
					$UI/EventLog.log_message(_collision_msg(b, a))
				else:
					var total: float = a.mass + b.mass
					b._vel = (b._vel * b.mass + a._vel * a.mass) / total
					b.mass = total
					var a_idx := _find_planet_idx(a)
					if a_idx >= 0:
						var b_idx := _find_planet_idx(b)
						_planet_data[a_idx].destroyed_by = PLANET_NAMES[b_idx] if b_idx >= 0 else "???"
					_disable_body(a)
					$ImpactFX.spawn_glow(a.position.lerp(b.position, 0.5), a.mass, contact_r)
					_trigger_impact_effects()
					$UI/EventLog.log_message(_collision_msg(a, b))

func _is_body_alive(body: Node2D) -> bool:
	if body.get_script() == _ASTEROID_SCRIPT:
		return body._alive
	return not body._dead

func _disable_body(body: Node2D):
	body.visible = false
	if body.get_script() == _ASTEROID_SCRIPT:
		body._alive = false
	else:
		body._dead = true
