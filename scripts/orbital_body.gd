class_name OrbitalBody
extends Node2D

const _TEX := preload("res://scripts/texture_utils.gd")
const _TRAIL := preload("res://scripts/trail_component.gd")
const DU := preload("res://scripts/draw_utils.gd")
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
@export var trail_max: int = 1200
var _trail_component: Node

signal collided_with_sun

func is_dead() -> bool:
	return _dead

func disable():
	if _trail_component:
		_trail_component.fade_out()
	_dead = true
	visible = false

func get_vel() -> Vector2:
	return _vel

func set_vel(v: Vector2):
	_vel = v

func _ready():
	_generate_texture()
	_reset()

func setup_trail(color: Color):
	_trail_component = _TRAIL.new()
	var head := DU.trail_head(color)
	var tail := DU.trail_tail(color)
	_trail_component.setup(tail, head, 1.5, trail_max)
	add_child(_trail_component)

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
	if _trail_component:
		_trail_component.clear()

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
		if _trail_component:
			_trail_component.fade_out()
		_dead = true
		visible = false
		collided_with_sun.emit()

	if _trail_component:
		_trail_component.record(position)
