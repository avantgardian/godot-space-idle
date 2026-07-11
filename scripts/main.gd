extends Node2D

@export var star_seed: int = 42
@export var sun_texture_size: int = 256
@export var camera_min_zoom: float = 0.3
@export var camera_max_zoom: float = 1.3
@export var camera_move_speed: float = 600.0
@export var camera_zoom_step: float = 0.05

const SCREEN_SIZE := Vector2(1920, 1080)
const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

const STAR_LAYERS := [
	{ count=500, min_r=0.2, max_r=0.5, min_b=0.08, max_b=0.25, motion_scale=0.003 },
	{ count=400, min_r=0.3, max_r=0.7, min_b=0.12, max_b=0.35, motion_scale=0.008 },
	{ count=300, min_r=0.4, max_r=1.0, min_b=0.2, max_b=0.45, motion_scale=0.018 },
	{ count=200, min_r=0.5, max_r=1.5, min_b=0.3, max_b=0.55, motion_scale=0.04 },
	{ count=120, min_r=0.8, max_r=2.0, min_b=0.4, max_b=0.75, motion_scale=0.08 },
	{ count=60,  min_r=1.5, max_r=3.0, min_b=0.6, max_b=1.0,  motion_scale=0.18 },
]

var _sun_glow_outer: Sprite2D
var _sun_glow_inner: Sprite2D
var _sun_time: float = 0.0
var _dragging: bool = false
var _drag_prev: Vector2
var _star_sprites: Array[Sprite2D]
var _star_motion_scales: Array[float]
var _target_zoom: float = 1.0
var _zoom_lerp_speed: float = 10.0
var _scroll_accum: float = 0.0

var sun_mass: float = 1.0
var _mass_label: Label
var _collision_flash: float = 0.0
var _impact_rings: Array[Dictionary]
var _asteroids: Array[Node2D]
var _asteroid_spawn_timer: float = 5.0
var _planet_data: Array[Dictionary]
const _ASTEROID_SCRIPT := preload("res://scripts/asteroid.gd")
const _STAR_SHADER := preload("res://shaders/star_blur.gdshader")
const _SUN_SHADER := preload("res://shaders/sun_noise.gdshader")
func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	_generate_star_layers()
	_generate_sun_texture()
	_apply_sun_shader()
	_generate_sun_glows()
	_setup_camera()
	_mass_label = $UI/MassLabel as Label
	_planet_data = [
		{ node = $Mercury, orbit_name = "MercuryOrbit", color0 = Color(1, 1, 1, 0.0), color1 = Color(1, 1, 1, 0.5), cf = 0.6, cc = Color(1, 0.9, 0.6, 0.5), cw = 2.0, cs = 48, ct = 0.8 },
		{ node = $Venus, orbit_name = "VenusOrbit", color0 = Color(1, 0.9, 0.6, 0.0), color1 = Color(1, 0.9, 0.6, 0.4), cf = 0.8, cc = Color(1, 0.8, 0.4, 0.6), cw = 3.0, cs = 64, ct = 1.2 },
		{ node = $Earth, orbit_name = "EarthOrbit", color0 = Color(0.3, 0.6, 1.0, 0.0), color1 = Color(0.3, 0.6, 1.0, 0.4), cf = 1.0, cc = Color(0.3, 0.7, 1.0, 0.7), cw = 3.5, cs = 72, ct = 1.5 },
		{ node = $Mars, orbit_name = "MarsOrbit", color0 = Color(0, 0, 0, 0.0), color1 = Color(1.0, 0.6, 0.1, 0.4), cf = 0.7, cc = Color(0.9, 0.4, 0.15, 0.5), cw = 2.0, cs = 40, ct = 0.9 },
		{ node = $Jupiter, orbit_name = "JupiterOrbit", color0 = Color(0.85, 0.6, 0.3, 0.0), color1 = Color(0.85, 0.6, 0.3, 0.4), cf = 2.0, cc = Color(0.85, 0.6, 0.3, 0.9), cw = 6.0, cs = 96, ct = 2.5 },
		{ node = $Saturn, orbit_name = "SaturnOrbit", color0 = Color(0.8, 0.7, 0.4, 0.0), color1 = Color(0.8, 0.7, 0.4, 0.4), cf = 1.8, cc = Color(0.8, 0.7, 0.4, 0.8), cw = 5.0, cs = 88, ct = 2.2 },
		{ node = $Uranus, orbit_name = "UranusOrbit", color0 = Color(0.4, 0.7, 0.9, 0.0), color1 = Color(0.4, 0.7, 0.9, 0.4), cf = 1.2, cc = Color(0.4, 0.7, 0.9, 0.6), cw = 3.0, cs = 64, ct = 1.6 },
		{ node = $Neptune, orbit_name = "NeptuneOrbit", color0 = Color(0.2, 0.3, 0.85, 0.0), color1 = Color(0.2, 0.3, 0.85, 0.4), cf = 1.3, cc = Color(0.2, 0.3, 0.85, 0.6), cw = 3.0, cs = 66, ct = 1.7 },
	]
	for p in _planet_data:
		p.node.collided_with_sun.connect(_on_planet_collided.bind(p))
		_create_orbit_line(p.orbit_name, p.node, p.color0, p.color1)

func _generate_star_layers():
	var rng := RandomNumberGenerator.new()
	rng.seed = star_seed

	var star_field := $StarField as Node2D
	var tile_scale := 2.0 / camera_min_zoom

	for cfg in STAR_LAYERS:
		var image := Image.create(int(SCREEN_SIZE.x), int(SCREEN_SIZE.y), false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)

		for _j in range(cfg.count):
			var x := rng.randf_range(0.0, SCREEN_SIZE.x)
			var y := rng.randf_range(0.0, SCREEN_SIZE.y)
			var radius := rng.randf_range(cfg.min_r, cfg.max_r)
			var brightness := rng.randf_range(cfg.min_b, cfg.max_b)
			var color := Color(brightness, brightness, brightness, 1.0)
			_draw_star_wrapped(image, x, y, radius, color)

		var texture := ImageTexture.create_from_image(image)

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(tile_scale, tile_scale)

		var mat := ShaderMaterial.new()
		mat.shader = _STAR_SHADER
		mat.set_shader_parameter("tiles", tile_scale)
		mat.set_shader_parameter("blur_amount", 0.0)
		sprite.material = mat

		_star_sprites.append(sprite)
		_star_motion_scales.append(cfg.motion_scale)
		star_field.add_child(sprite)

func _draw_star_wrapped(image: Image, x: float, y: float, radius: float, color: Color):
	var w := image.get_width()
	var h := image.get_height()
	_draw_star_on_image(image, x, y, radius, color)
	if x - radius < 0:
		_draw_star_on_image(image, x + w, y, radius, color)
		if y - radius < 0:
			_draw_star_on_image(image, x + w, y + h, radius, color)
		if y + radius >= h:
			_draw_star_on_image(image, x + w, y - h, radius, color)
	if x + radius >= w:
		_draw_star_on_image(image, x - w, y, radius, color)
		if y - radius < 0:
			_draw_star_on_image(image, x - w, y + h, radius, color)
		if y + radius >= h:
			_draw_star_on_image(image, x - w, y - h, radius, color)
	if y - radius < 0:
		_draw_star_on_image(image, x, y + h, radius, color)
	if y + radius >= h:
		_draw_star_on_image(image, x, y - h, radius, color)

func _draw_star_on_image(image: Image, cx: float, cy: float, radius: float, color: Color):
	var r := ceili(radius)
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var dist := Vector2(dx, dy).length()
			if dist <= radius:
				var px := int(cx) + dx
				var py := int(cy) + dy
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					var alpha := 1.0
					if dist > radius * 0.7 and radius > 1.0:
						alpha = 1.0 - (dist - radius * 0.7) / (radius * 0.3)
					var final_color := Color(color.r, color.g, color.b, color.a * alpha)
					var existing := image.get_pixel(px, py)
					image.set_pixel(px, py, final_color.blend(existing))

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

func _create_orbit_line(line_name: String, planet: Node2D, color0: Color, color1: Color):
	var line := Line2D.new()
	line.name = line_name
	line.width = 1.5
	line.antialiased = true
	var grad := Gradient.new()
	grad.set_color(0, color0)
	grad.set_color(1, color1)
	line.gradient = grad
	add_child(line)
	move_child(line, planet.get_index())

func _setup_camera():
	var camera := $Camera2D as Camera2D
	camera.zoom = Vector2(1, 1)
	camera.limit_smoothed = true
	camera.position = Vector2.ZERO

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
		var line := get_node(p.orbit_name) as Line2D
		if line:
			line.points = p.node.get_trail()

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

	var camera := $Camera2D as Camera2D
	var cur_zoom: float = camera.zoom.x
	if abs(cur_zoom - _target_zoom) > 0.0001:
		var new_zoom: float = lerp(cur_zoom, _target_zoom, _zoom_lerp_speed * delta)
		if abs(new_zoom - _target_zoom) < 0.001:
			new_zoom = _target_zoom
		_apply_zoom(new_zoom)
	else:
		_apply_zoom(_target_zoom)

	_update_star_parallax(camera)

	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if move != Vector2.ZERO:
		move = move.normalized() * camera_move_speed * delta / camera.zoom.x
		camera.position += move

func _update_star_parallax(camera: Camera2D):
	var cam_pos := camera.position
	var world_half := SCREEN_SIZE * 0.5 / camera.zoom.x

	for i in _star_sprites.size():
		var sprite := _star_sprites[i]
		var ms := _star_motion_scales[i]
		var origin := -cam_pos * ms
		sprite.position = Vector2(
			origin.x + _align_floor(cam_pos.x - world_half.x - origin.x, SCREEN_SIZE.x),
			origin.y + _align_floor(cam_pos.y - world_half.y - origin.y, SCREEN_SIZE.y)
		)

func _align_floor(offset: float, period: float) -> float:
	return floor(offset / period) * period

func _on_planet_collided(p: Dictionary):
	sun_mass += p.node.mass
	_collision_flash = max(_collision_flash, p.cf)
	_spawn_impact_ring(p.cc, p.cw, p.cs, p.ct)

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

func _apply_zoom(new_zoom: float):
	var camera := $Camera2D as Camera2D
	camera.zoom = Vector2(new_zoom, new_zoom)

	var blur_t := (new_zoom - camera_min_zoom) / (camera_max_zoom - camera_min_zoom)
	var blur_amount := blur_t * blur_t * 5.0
	for sprite in _star_sprites:
		var mat := sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("blur_amount", blur_amount)

func _zoom_in():
	_target_zoom = clamp(_target_zoom + camera_zoom_step, camera_min_zoom, camera_max_zoom)

func _zoom_out():
	_target_zoom = clamp(_target_zoom - camera_zoom_step, camera_min_zoom, camera_max_zoom)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()
	if event is InputEventPanGesture:
		_scroll_accum += event.delta.y
		while _scroll_accum >= 0.3:
			_zoom_out()
			_scroll_accum -= 0.3
		while _scroll_accum <= -0.3:
			_zoom_in()
			_scroll_accum += 0.3

func _unhandled_input(event):
	var camera := $Camera2D as Camera2D

	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = camera.get_canvas_transform() * $Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.button_index == MOUSE_BUTTON_LEFT and on_sun:
			sun_mass += 0.01
			return
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = true
			_drag_prev = event.position

	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		var delta_vec: Vector2 = event.position - _drag_prev
		camera.position -= delta_vec / camera.zoom.x
		_drag_prev = event.position

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL:
			_zoom_in()
		elif event.keycode == KEY_MINUS:
			_zoom_out()


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
					_disable_body(b)
					_spawn_collision_effect(a.position.lerp(b.position, 0.5), b.mass, contact_r)
				else:
					var total: float = a.mass + b.mass
					b._vel = (b._vel * b.mass + a._vel * a.mass) / total
					b.mass = total
					_disable_body(a)
					_spawn_collision_effect(a.position.lerp(b.position, 0.5), a.mass, contact_r)

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
		body._respawn_timer = 0.0

func _spawn_collision_effect(pos: Vector2, mass: float, contact_radius: float = 1.0):
	var t := clampf(mass * 10.0, 0.2, 1.0)
	_collision_flash = max(_collision_flash, t)

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
