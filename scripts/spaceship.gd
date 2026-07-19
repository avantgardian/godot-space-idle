class_name Spaceship
extends Node2D

const MAX_SPEED: float = 300.0
const THRUST_FORCE: float = 160.0
const REVERSE_FORCE: float = 80.0
const ROTATION_SPEED: float = 3.0
const DAMPING: float = 0.8
const COLLISION_RADIUS: float = 14.0

var mass: float = 0.001
var collision_radius: float = COLLISION_RADIUS
var input_active: bool = false

var _pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _alive: bool = true

var _thrust_sprite: Sprite2D

func _ready():
	_generate_body_texture()
	_generate_indicator_ring()
	_generate_thrust_flame()
	_thrust_sprite = $ThrustFlame
	_thrust_sprite.visible = false
	position = _pos

func init(start_pos: Vector2):
	_pos = start_pos
	position = start_pos

func _process(delta):
	if not _alive:
		return

	if input_active:
		var rotate_left := Input.is_key_pressed(KEY_LEFT)
		var rotate_right := Input.is_key_pressed(KEY_RIGHT)
		var thrust_forward := Input.is_key_pressed(KEY_UP)
		var thrust_reverse := Input.is_key_pressed(KEY_DOWN)

		if rotate_left and not rotate_right:
			_angle -= ROTATION_SPEED * delta
		elif rotate_right and not rotate_left:
			_angle += ROTATION_SPEED * delta

		var thrust_dir := Vector2.UP.rotated(_angle)

		var thrusting := false
		if thrust_forward:
			_vel += thrust_dir * THRUST_FORCE * delta
			thrusting = true
		if thrust_reverse:
			_vel -= thrust_dir * REVERSE_FORCE * delta
			thrusting = true

		_thrust_sprite.visible = thrusting
	else:
		_thrust_sprite.visible = false

	_vel *= max(1.0 - DAMPING * delta, 0.0)

	var speed := _vel.length()
	if speed > MAX_SPEED:
		_vel = _vel.normalized() * MAX_SPEED

	_pos += _vel * delta
	position = _pos
	rotation = _angle

func enforce_sun_barrier(min_dist: float):
	var r := _pos.length()
	if r < min_dist:
		if r < 0.01:
			_pos = Vector2(min_dist, 0.0)
		else:
			_pos = _pos.normalized() * min_dist
		position = _pos
		var radial_dir := _pos.normalized()
		var radial_vel := _vel.dot(radial_dir)
		if radial_vel < 0.0:
			_vel -= radial_dir * radial_vel

func is_alive() -> bool:
	return _alive

func is_dead() -> bool:
	return not _alive

func get_vel() -> Vector2:
	return _vel

func set_vel(v: Vector2):
	_vel = v

func disable():
	_alive = false
	visible = false

func _generate_body_texture():
	var size: int = 32
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx: float = size / 2.0
	var tip_y: float = 3.0
	var base_y: float = 23.0
	var engine_y: float = 29.0
	var half_base: float = 11.0
	var half_engine: float = 12.0

	for x in range(size):
		for y in range(size):
			var fx: float = float(x)
			var fy: float = float(y)
			var dx: float = abs(fx - cx)

			if fy >= tip_y and fy <= base_y:
				var half_w: float = (fy - tip_y) / (base_y - tip_y) * half_base
				if dx <= half_w:
					var edge_dist: float = half_w - dx
					if edge_dist < 2.0:
						image.set_pixel(x, y, Color(0.45, 0.6, 0.75, 1.0))
					else:
						image.set_pixel(x, y, Color(0.2, 0.3, 0.5, 1.0))

			elif fy > base_y and fy <= engine_y:
				if dx <= half_engine * 0.7:
					if dx <= half_engine * 0.4:
						image.set_pixel(x, y, Color(0.3, 0.4, 0.55, 1.0))
					else:
						image.set_pixel(x, y, Color(0.25, 0.35, 0.5, 1.0))

	var cockpit_y: int = int(tip_y + 4)
	image.set_pixel(int(cx), cockpit_y, Color(0.7, 0.85, 1.0, 1.0))
	image.set_pixel(int(cx), cockpit_y + 1, Color(0.7, 0.85, 1.0, 0.8))

	var body: Sprite2D = Sprite2D.new()
	body.name = "Body"
	body.texture = ImageTexture.create_from_image(image)
	body.centered = true
	add_child(body)

func _generate_indicator_ring():
	var size: int = 56
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var ring_r: float = 22.0
	var ring_width: float = 2.0
	var gap_angle: float = PI / 6.0
	var gap_half: float = gap_angle / 2.0

	for x in range(size):
		for y in range(size):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var dist: float = sqrt(dx * dx + dy * dy)

			if abs(dist - ring_r) <= ring_width:
				var angle_from_up: float = abs(atan2(dx, -dy))
				if angle_from_up > gap_half:
					var fade_dist: float = angle_from_up - gap_half
					var alpha: float = 0.8
					if fade_dist < 0.15:
						alpha = fade_dist / 0.15 * 0.8
					image.set_pixel(x, y, Color(0.3, 0.85, 0.95, alpha))

	var chevron_y: int = int(cy - ring_r - ring_width - 1)
	var chevron_size: int = 5
	for i in range(chevron_size):
		for j in range(-i, i + 1):
			var px: int = int(cx) + j
			var py: int = chevron_y - i
			if px >= 0 and px < size and py >= 0 and py < size:
				image.set_pixel(px, py, Color(0.4, 0.9, 1.0, 0.9))

	var ring: Sprite2D = Sprite2D.new()
	ring.name = "IndicatorRing"
	ring.texture = ImageTexture.create_from_image(image)
	ring.centered = true
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	add_child(ring)

func _generate_thrust_flame():
	var size: int = 24
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx: float = size / 2.0

	for x in range(size):
		for y in range(size):
			var dx: float = float(x) - cx
			var dy: float = float(y)
			if dy > 0 and dy < 18:
				var width: float = 3.0 + dy * 0.4
				if abs(dx) < width:
					var t: float = dy / 18.0
					var inner: float = abs(dx) / width
					var alpha: float = (1.0 - t) * (1.0 - inner * inner) * 0.85
					var g: float = clampf(0.7 - t * 0.6, 0.05, 0.7)
					image.set_pixel(x, y, Color(1.0, g, 0.0, clampf(alpha, 0.0, 1.0)))

	var flame: Sprite2D = Sprite2D.new()
	flame.name = "ThrustFlame"
	flame.texture = ImageTexture.create_from_image(image)
	flame.centered = true
	flame.position = Vector2(0, 14)
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flame.material = mat
	flame.visible = false
	add_child(flame)
