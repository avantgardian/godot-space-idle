extends Node2D

@export var star_seed: int = 42
@export var sun_texture_size: int = 256

const SCREEN_SIZE := Vector2(1920, 1080)
const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

var _sun_glow_outer: Sprite2D
var _sun_glow_inner: Sprite2D
var _sun_time: float = 0.0
const PLANET_SPEEDS := [47.4, 35.0, 29.8, 24.1, 13.1, 9.7, 6.8, 5.4]

var sun_mass: float = 1.0
var _mass_label: Label
var _planet_mass_labels: Array[Label]
var _collision_flash: float = 0.0
var _impact_rings: Array[Dictionary]
var _asteroids: Array[Node2D]
var _asteroid_spawn_timer: float = 5.0
var _planet_data: Array[Dictionary]
const _ASTEROID_SCRIPT := preload("res://scripts/asteroid.gd")
const _SUN_SHADER := preload("res://shaders/sun_noise.gdshader")
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
	_generate_sun_texture()
	_apply_sun_shader()
	_generate_sun_glows()
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
	_setup_planet_mass_ui()
	_setup_pause_button()
	_setup_post_process()
	_setup_event_log()

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

func _setup_event_log():
	var panel := Panel.new()
	panel.name = "EventLogPanel"
	panel.position = Vector2(16, SCREEN_SIZE.y - 300)
	panel.size = Vector2(360, 280)
	panel.clip_contents = true

	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.04, 0.1, 0.88)
	psb.border_color = Color(0.35, 0.45, 0.65, 0.6)
	psb.border_width_left = 1
	psb.border_width_top = 1
	psb.border_width_right = 1
	psb.border_width_bottom = 1
	psb.corner_radius_top_left = 4
	psb.corner_radius_top_right = 4
	psb.corner_radius_bottom_right = 4
	psb.corner_radius_bottom_left = 4
	psb.content_margin_left = 8
	psb.content_margin_right = 8
	psb.content_margin_top = 6
	psb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", psb)

	var log_container := VBoxContainer.new()
	log_container.name = "EventLog"
	log_container.position = Vector2(10, 8)
	log_container.size = Vector2(340, 264)
	log_container.add_theme_constant_override("separation", 2)
	panel.add_child(log_container)

	$UI.add_child(panel)

func _body_name(body: Node2D) -> String:
	var idx := _find_planet_idx(body)
	return PLANET_NAMES[idx] if idx >= 0 else "Asteroid"

func _collision_msg(victim: Node2D, absorber: Node2D) -> String:
	if _find_planet_idx(victim) < 0 or _find_planet_idx(absorber) < 0:
		return _body_name(victim) + " collided with " + _body_name(absorber)
	return _body_name(victim) + " was destroyed by " + _body_name(absorber)

func _log_event(msg: String):
	var event_log := $UI.get_node_or_null("EventLogPanel/EventLog") as VBoxContainer
	if not event_log:
		return
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	event_log.add_child(lbl)
	event_log.move_child(lbl, 0)
	_event_log_entries.append({ label = lbl, age = 0.0 })
	while _event_log_entries.size() > MAX_LOG_ENTRIES:
		var oldest := _event_log_entries[0]
		_event_log_entries.remove_at(0)
		oldest.label.queue_free()

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

func _setup_planet_mass_ui():
	_planet_mass_labels = []
	var container := VBoxContainer.new()
	container.name = "PlanetMassList"
	container.position = Vector2(16, 44)
	container.add_theme_constant_override("separation", 2)
	$UI.add_child(container)

	var title := Label.new()
	title.text = "Planets (M☉):"
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)

	for p in _planet_data:
		var lbl := Label.new()
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
		lbl.add_theme_font_size_override("font_size", 12)
		container.add_child(lbl)
		_planet_mass_labels.append(lbl)


func _generate_sun_texture():
	var size := sun_texture_size
	var radius := size / 2.0
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center)
			if dist <= radius:
				var t := dist / radius
				var color: Color
				if t < 0.2:
					color = Color(1.0, 0.95, 0.8)
				elif t < 0.6:
					var lt := (t - 0.2) / 0.4
					color = Color(1.0, 0.95, 0.8).lerp(Color(1.0, 0.7, 0.2), lt)
				else:
					var lt := (t - 0.6) / 0.4
					color = Color(1.0, 0.7, 0.2).lerp(Color(0.8, 0.3, 0.05), lt)
				var alpha := 1.0
				if t > 0.85:
					alpha = 1.0 - (t - 0.85) / 0.15
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))

	var texture := ImageTexture.create_from_image(image)
	$Sun.texture = texture

func _apply_sun_shader():
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _SUN_SHADER
	shader_mat.set_shader_parameter("time", 0.0)
	$Sun.material = shader_mat

func _generate_sun_glows():
	var add_mat := func() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

	var glow_tex := func(size_ratio: float) -> Texture2D:
		var size := int(sun_texture_size * size_ratio)
		var radius := size / 2.0
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		var center := Vector2(radius, radius)
		for x in range(size):
			for y in range(size):
				var dist := Vector2(x, y).distance_to(center)
				if dist <= radius:
					var t := dist / radius
					image.set_pixel(x, y, Color(1.0, 0.5 + 0.5 * (1.0 - t), 0.1, (1.0 - t * t) * 0.6))
		return ImageTexture.create_from_image(image)

	_sun_glow_outer = Sprite2D.new()
	_sun_glow_outer.texture = glow_tex.call(2.0)
	_sun_glow_outer.centered = true
	_sun_glow_outer.name = "GlowOuter"
	_sun_glow_outer.z_index = -2
	_sun_glow_outer.material = add_mat.call()
	$Sun.add_child(_sun_glow_outer)

	_sun_glow_inner = Sprite2D.new()
	_sun_glow_inner.texture = glow_tex.call(1.25)
	_sun_glow_inner.centered = true
	_sun_glow_inner.name = "GlowInner"
	_sun_glow_inner.z_index = -1
	_sun_glow_inner.material = add_mat.call()
	$Sun.add_child(_sun_glow_inner)

var _planet_popup: Panel
var _popup_labels: Dictionary

var _post_process_mat: ShaderMaterial
var _ca_impact: float = 0.0
var _event_log_entries: Array[Dictionary] = []
const EVENT_LOG_DURATION := 60.0
const MAX_LOG_ENTRIES := 30

func _process(delta):
	_sun_time += delta

	var sun := $Sun as Sprite2D
	sun.material.set_shader_parameter("time", _sun_time)
	sun.rotation += delta * 0.2
	var breathe := sin(_sun_time * 0.5) * 0.04 + 1.0
	sun.scale = Vector2(breathe, breathe)

	var mass_t: float = clamp((sun_mass - 1.0) / 2.0, 0.0, 1.0)
	var temp_color: Color = Color(1.0, 1.0, 0.5).lerp(Color(1.0, 0.35, 0.05), mass_t)
	sun.modulate = temp_color * (sin(_sun_time * 1.2) * 0.05 + 0.95)

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

	var outer_pulse := sin(_sun_time * 0.25) * 0.12 + 1.12
	var outer_alpha := sin(_sun_time * 0.2 + 0.5) * 0.2 + 0.4
	var inner_pulse := sin(_sun_time * 0.35 + 1.2) * 0.06 + 1.06
	var inner_alpha := sin(_sun_time * 0.3 + 0.3) * 0.15 + 0.6

	if _collision_flash > 0.0:
		var t: float = _collision_flash / 0.6
		var flash: float = t * t
		sun.modulate = sun.modulate.lerp(Color.WHITE, flash * 0.7)
		sun.scale = Vector2(breathe, breathe) * (1.0 + flash * 0.15)
		var pulse := 1.0 + flash * 0.4
		_sun_glow_outer.scale = Vector2(outer_pulse, outer_pulse) * pulse
		_sun_glow_outer.modulate = Color(1, 1, 1, outer_alpha + flash * 0.5)
		_sun_glow_inner.scale = Vector2(inner_pulse, inner_pulse) * pulse
		_sun_glow_inner.modulate = Color(1, 1, 1, inner_alpha + flash * 0.5)
		_collision_flash -= delta
	else:
		_sun_glow_outer.scale = Vector2(outer_pulse, outer_pulse)
		_sun_glow_outer.modulate = Color(1, 1, 1, outer_alpha)
		_sun_glow_inner.scale = Vector2(inner_pulse, inner_pulse)
		_sun_glow_inner.modulate = Color(1, 1, 1, inner_alpha)

	for i in range(_impact_rings.size() - 1, -1, -1):
		var rd := _impact_rings[i]
		rd.timer -= delta
		var total: float = rd.get("initial", 0.8)
		var t: float = rd.timer / total
		var base: float = rd.get("base_scale", 1.0)
		var s := base * (1.0 + (1.0 - t) * 3.0)
		rd.ring.scale = Vector2(s, s)
		if "is_glow" in rd:
			rd.ring.modulate.a = t * t
		else:
			rd.ring.default_color.a = t * 0.6
		if rd.timer <= 0.0:
			rd.ring.queue_free()
			_impact_rings.remove_at(i)

	if _mass_label:
		_mass_label.text = "M☉ = %.7f" % sun_mass
		for i in _planet_data.size():
			var p := _planet_data[i]
			var m: float = p.node.mass
			var pct: float = (m - p.initial_mass) / p.initial_mass * 100.0
			var change := ""
			if pct > 0.001:
				var pct_str: String = str(pct)
				var dot := pct_str.find(".")
				if dot > 0 and dot + 2 < pct_str.length():
					pct_str = pct_str.left(dot + 2)
				change = " +%s%%" % pct_str
			var status := ""
			if p.node._dead:
				status = " (Destroyed by " + p.destroyed_by + ")" if p.destroyed_by else " (Destroyed)"
			var line: String = "%s: %s%s%s" % [PLANET_NAMES[i], str(m), change, status]
			_planet_mass_labels[i].text = line

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

	for i in range(_event_log_entries.size() - 1, -1, -1):
		var entry := _event_log_entries[i]
		entry.age += delta
		var t: float = entry.age / EVENT_LOG_DURATION
		if t >= 1.0:
			entry.label.queue_free()
			_event_log_entries.remove_at(i)
		else:
			entry.label.modulate.a = 1.0 - ease(t, 0.5)

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
	_collision_flash = max(_collision_flash, p.cf)
	_spawn_impact_ring(p.cc, p.cw, p.cs, p.ct)
	_trigger_impact_effects()
	var p_idx := _find_planet_idx(p.node)
	_log_event(PLANET_NAMES[p_idx] + " collided with the Sun")

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
	_collision_flash = max(_collision_flash, 0.2)
	_spawn_impact_ring(Color(1, 0.7, 0.3, 0.3), 1.5, 24, 0.4)
	_trigger_impact_effects()
	_log_event("Asteroid collided with the Sun")

func _spawn_impact_ring(color: Color, width: float, segments: int, timer: float):
	var ring := Line2D.new()
	ring.default_color = color
	ring.width = width
	ring.antialiased = true
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var a := (float(i) / segments) * TAU
		pts.append(Vector2(cos(a), sin(a)))
	ring.points = pts
	add_child(ring)
	_impact_rings.append({ ring = ring, timer = timer })

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
					_spawn_collision_effect(a.position.lerp(b.position, 0.5), b.mass, contact_r)
					_log_event(_collision_msg(b, a))
				else:
					var total: float = a.mass + b.mass
					b._vel = (b._vel * b.mass + a._vel * a.mass) / total
					b.mass = total
					var a_idx := _find_planet_idx(a)
					if a_idx >= 0:
						var b_idx := _find_planet_idx(b)
						_planet_data[a_idx].destroyed_by = PLANET_NAMES[b_idx] if b_idx >= 0 else "???"
					_disable_body(a)
					_spawn_collision_effect(a.position.lerp(b.position, 0.5), a.mass, contact_r)
					_log_event(_collision_msg(a, b))

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

func _spawn_collision_effect(pos: Vector2, mass: float, contact_radius: float = 1.0):
	var t := clampf(mass * 10.0, 0.2, 1.0)
	_trigger_impact_effects()

	var tex_size := 64
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var half := tex_size / 2.0
	var max_r := half - 1.0
	for x in range(tex_size):
		for y in range(tex_size):
			var dx := x - half
			var dy := y - half
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var nt := dist / max_r
				var alpha := (1.0 - nt * nt) * t * 0.8
				image.set_pixel(x, y, Color(1.0, 0.85, 0.3, alpha))

	var glow := Sprite2D.new()
	glow.texture = ImageTexture.create_from_image(image)
	glow.centered = true
	glow.position = pos
	glow.modulate = Color(1, 1, 1, 1)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)
	var duration := 0.5 + t * 1.0
	_impact_rings.append({ ring = glow, timer = duration, initial = duration, base_scale = contact_radius / 32.0, is_glow = true })
