class_name Asteroid
extends Node2D

const TEX := preload("res://scripts/texture_utils.gd")
const PAL := preload("res://scripts/tron_palette.gd")
const PLANET_GRAVITY_SCALE: float = 5.0
const PLANET_MASS_EXPONENT: float = 0.3
const PLANET_SOFTENING: float = 150.0
const _TRAIL := preload("res://scripts/trail_component.gd")

var sun_mass: float = 1.0
var gm_unit: float = 0.0
var mass: float = 0.0
var collision_radius: float = 6.0
var _pos: Vector2
var _vel: Vector2
var _alive: bool = false
var _sprite: Sprite2D
var _trail_component: Node
var _planets: Array[Dictionary] = []

signal collided_with_sun

func disable():
	if _trail_component:
		_trail_component.fade_out()
	_alive = false
	visible = false

func set_planet_data(data: Array[Dictionary]):
	_planets = data

func get_vel() -> Vector2:
	return _vel

func set_vel(v: Vector2):
	_vel = v

func _ready():
	_generate_texture()
	_trail_component = _TRAIL.new()
	var accent := PAL.ACCENT
	_trail_component.setup(
		Color(accent.r, accent.g, accent.b, 0.0),
		Color(accent.r, accent.g, accent.b, 0.5),
		1.0, 600)
	add_child(_trail_component)

func _generate_texture():
	_sprite = Sprite2D.new()
	_sprite.texture = TEX.make_noisy_blob(14, randi())
	_sprite.centered = true
	add_child(_sprite)

func spawn():
	mass = randf_range(1.5e-8, 6e-8)
	var spawn_r := randf_range(2400.0, 3200.0)
	var entry_angle := randf_range(0.0, TAU)
	_pos = Vector2(cos(entry_angle), sin(entry_angle)) * spawn_r

	var gm := gm_unit * sun_mass
	var v_circ := sqrt(gm / spawn_r)
	var radial := -randf_range(0.1, 0.4) * v_circ
	var tangential := randf_range(0.2, 2.5) * v_circ
	var dir := Vector2(cos(entry_angle), sin(entry_angle))
	var tangent := Vector2(-dir.y, dir.x)
	_vel = dir * radial + tangent * tangential

	position = _pos
	if _trail_component:
		_trail_component.clear()
	_alive = true
	visible = true

func _process(delta):
	if not _alive:
		return

	var gm := gm_unit * sun_mass
	var r2 := _pos.length_squared()
	if r2 < 4.0:
		r2 = 4.0
	var r := sqrt(r2)
	var acc := -gm / r2 * _pos / r
	for pl in _planets:
		var offset: Vector2 = pl.pos - _pos
		var dist_sq: float = offset.length_squared()
		var dist: float = sqrt(dist_sq)
		var softened_r2: float = dist_sq + PLANET_SOFTENING * PLANET_SOFTENING
		acc += gm_unit * pow(pl.mass, PLANET_MASS_EXPONENT) / softened_r2 * offset / dist * PLANET_GRAVITY_SCALE
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	_sprite.rotation += delta * 1.5

	var sun_r := OrbitalBody.sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		if _trail_component:
			_trail_component.fade_out()
		_alive = false
		visible = false
		collided_with_sun.emit()
		return

	if r > 5000.0:
		if _trail_component:
			_trail_component.fade_out()
		_alive = false
		visible = false
		return

	if _trail_component:
		_trail_component.record(position)

func is_alive() -> bool:
	return _alive
