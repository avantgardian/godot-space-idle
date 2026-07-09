extends Node2D

@export var orbit_radius: float = 950.0
@export var orbit_period: float = 123.0
@export var start_angle: float = 4.0

const G: float = 1.0

var sun_mass: float = 1.0
var mass: float = 0.107
var collision_radius: float = 13.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
var _respawn_timer: float = 0.0
var _trail: PackedVector2Array
var _trail_tick: int = 0
var _sprite: Sprite2D

signal collided_with_sun

func _ready():
	_generate_texture()
	_reset()

func _generate_texture():
	var size := 26
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx := size / 2.0
	var cy := size / 2.0
	for x in range(size):
		for y in range(size):
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			var max_r := size / 2.0 - 1
			if dist <= max_r:
				var t := dist / max_r
				var brightness := 0.6 + 0.4 * (1.0 - t)
				var r := 0.75 * brightness
				var g := 0.35 * brightness
				var b := 0.15 * brightness
				var alpha := 1.0
				if t > 0.85:
					alpha = 1.0 - (t - 0.85) / 0.15
				image.set_pixel(x, y, Color(r, g, b, alpha))
	_sprite = Sprite2D.new()
	_sprite.texture = ImageTexture.create_from_image(image)
	_sprite.centered = true
	add_child(_sprite)

func _reset():
	mass = 0.107
	var gm := _initial_gm()
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent := Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(gm / orbit_radius)
	position = _pos
	_dead = false
	visible = true
	_trail.clear()

func _initial_gm() -> float:
	return 4.0 * PI * PI * orbit_radius * orbit_radius * orbit_radius / (orbit_period * orbit_period)

func _process(delta):
	if _dead:
		_respawn_timer += delta
		if _respawn_timer >= 2.0:
			_respawn_timer = 0.0
			_reset()
		return

	var gm := _initial_gm() * sun_mass
	var r2 := _pos.length_squared()
	if r2 < 1.0:
		r2 = 1.0
	var r := sqrt(r2)
	var acc := -gm / r2 * _pos / r
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	var sun_r := (128.0 + sqrt(sun_mass) * 8.0) * 0.85 + collision_radius
	if r < sun_r:
		_dead = true
		_respawn_timer = 0.0
		visible = false
		collided_with_sun.emit()

	_trail_tick += 1
	if _trail_tick % 2 == 0:
		_trail.append(position)
		if _trail.size() > 1500:
			_trail.remove_at(0)

func get_trail() -> PackedVector2Array:
	if _dead or _trail.size() < 2:
		return PackedVector2Array()
	return _trail
