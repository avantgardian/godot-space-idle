extends Node2D

@export var orbit_radius: float = 350.0
@export var orbit_period: float = 30.0
@export var start_angle: float = 0.0

const G: float = 1.0

var sun_mass: float = 1.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
var _respawn_timer: float = 0.0
var _trail: PackedVector2Array
var _trail_tick: int = 0

signal collided_with_sun

func _ready():
	_reset()

func _reset():
	var gm := _initial_gm()
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent := Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(gm / orbit_radius)
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

	var sun_r := 128.0 + sqrt(sun_mass) * 8.0
	var collision_r := sun_r * 0.85 + 18.0
	if r < collision_r:
		_dead = true
		_respawn_timer = 0.0
		visible = false
		collided_with_sun.emit()

	_trail_tick += 1
	if _trail_tick % 2 == 0:
		_trail.append(position)
		if _trail.size() > 900:
			_trail.remove_at(0)

func get_trail() -> PackedVector2Array:
	if _dead or _trail.size() < 2:
		return PackedVector2Array()
	return _trail

func predict_orbit(steps: int = 1200, future_mass: float = -1.0) -> PackedVector2Array:
	if _dead:
		return PackedVector2Array()

	var gm := _initial_gm() * (sun_mass if future_mass < 0.0 else future_mass)
	var sim_pos := _pos
	var sim_vel := _vel
	var dt := 1.0 / 60.0
	var pts := PackedVector2Array()
	pts.resize(steps)
	var hit_radius := (128.0 + sqrt(sun_mass) * 8.0) * 0.85 + 18.0

	for i in range(steps):
		pts[i] = sim_pos
		var r2 := sim_pos.length_squared()
		if r2 < 4.0:
			pts.resize(i + 1)
			break
		if r2 < hit_radius * hit_radius:
			pts.resize(i + 1)
			break
		var r := sqrt(r2)
		var acc := -gm / r2 * sim_pos / r
		sim_vel += acc * dt
		sim_pos += sim_vel * dt

	return pts
