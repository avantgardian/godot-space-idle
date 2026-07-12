class_name OrbitalBody
extends Node2D

const _TEX := preload("res://scripts/texture_utils.gd")
var _sprite: Sprite2D

@export var orbit_radius: float = 500.0
@export var orbit_period: float = 48.0
@export var start_angle: float = 0.0

var sun_mass: float = 1.0
@export var mass: float = 1.0
@export var collision_radius: float = 20.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
var _trail: PackedVector2Array
var _trail_tick: int = 0
@export var trail_max: int = 1200
var _trail_line: Line2D

signal collided_with_sun

func is_dead() -> bool:
	return _dead

func disable():
	_dead = true
	visible = false

func get_vel() -> Vector2:
	return _vel

func set_vel(v: Vector2):
	_vel = v

func _ready():
	_generate_texture()
	_reset()

func setup_trail(color0: Color, color1: Color):
	_trail_line = Line2D.new()
	_trail_line.top_level = true
	_trail_line.width = 1.5
	_trail_line.antialiased = true
	_trail_line.z_index = -1
	var grad := Gradient.new()
	grad.set_color(0, color0)
	grad.set_color(1, color1)
	_trail_line.gradient = grad
	add_child(_trail_line)

func _generate_texture():
	var tex_size := _get_planet_texture_size()
	_sprite = Sprite2D.new()
	_sprite.texture = _TEX.make_circle_texture(tex_size, _get_planet_color)
	_sprite.centered = true
	add_child(_sprite)

func _get_planet_texture_size() -> int:
	return 32

func _get_planet_color(_t: float, _x: int, _y: int) -> Color:
	return Color.WHITE

func _reset():
	var gm := _initial_gm()
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent := Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(gm / orbit_radius)
	position = _pos
	_dead = false
	visible = true
	_trail.clear()

static func sun_collision_r(mass_solar: float) -> float:
	return (128.0 + sqrt(mass_solar) * 8.0) * 0.85

func _initial_gm() -> float:
	return 4.0 * PI * PI * orbit_radius * orbit_radius * orbit_radius / (orbit_period * orbit_period)

func _process(delta):
	if _dead:
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

	var sun_r := sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		_dead = true
		visible = false
		collided_with_sun.emit()

	_trail_tick += 1
	if _trail_tick % 2 == 0:
		_trail.append(position)
		if _trail.size() > trail_max:
			_trail.remove_at(0)

	if _trail_line:
		_trail_line.points = get_trail()

func get_trail() -> PackedVector2Array:
	if _dead or _trail.size() < 2:
		return PackedVector2Array()
	return _trail
