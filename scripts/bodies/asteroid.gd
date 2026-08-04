class_name Asteroid
extends Node2D

signal collided_with_sun

enum AsteroidArchetype { C_TYPE, S_TYPE, M_TYPE, X_TYPE }

const TEX := preload("res://scripts/util/texture_utils.gd")
const PAL_T := preload("res://scripts/util/tron_palette.gd")
const PAL_P := preload("res://scripts/util/planet_palette.gd")
const DU := preload("res://scripts/util/draw_utils.gd")
const ASTEROID_SHADER := preload("res://shaders/bodies/asteroid_surface.gdshader")
const PLANET_GRAVITY_SCALE: float = 5.0
const PLANET_MASS_EXPONENT: float = 0.3
const PLANET_SOFTENING: float = 150.0
const _TRAIL := preload("res://scripts/components/trail_component.gd")
const TEXTURE_SIZE := 24

const ARCHETYPE_WEIGHTS := [0.55, 0.25, 0.10, 0.10]

var sun_mass: float = 1.0
var gm_unit: float = 0.0
var mass: float = 0.0
var collision_radius: float = 0.0
var _pos: Vector2
var _vel: Vector2
var _alive: bool = false
var _sprite: Sprite2D
var _shader_mat: ShaderMaterial
var _asteroid_time: float = 0.0
var _asteroid_seed: int = 0
var _archetype: int = AsteroidArchetype.C_TYPE
var _trail_component: Node
var _planets: Array[Dictionary] = []
var _body_color: Color = Color.WHITE
var _visual_radius_px: float = 12.0
var _spin_rate: float = 1.5
var _density_ratio: float = 1.0


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
	_ensure_init()


func _ensure_init():
	if _sprite:
		return
	_asteroid_seed = randi()
	_generate_texture()
	_trail_component = _TRAIL.new()
	var head := PAL_T.ASTEROID_TRAIL
	var tail := Color(PAL_T.ASTEROID_TRAIL, 0.0)
	_trail_component.setup(tail, head, 1.0, 600)
	add_child(_trail_component)


func _generate_texture():
	_sprite = Sprite2D.new()

	var rng := RandomNumberGenerator.new()
	rng.seed = _asteroid_seed
	var roll := rng.randf()
	var cum := 0.0
	_archetype = AsteroidArchetype.C_TYPE
	for i in range(ARCHETYPE_WEIGHTS.size()):
		cum += ARCHETYPE_WEIGHTS[i]
		if roll <= cum:
			_archetype = i
			break

	var hi: Color
	var lo: Color
	var ambient: float
	var relief_base: float
	var crater_count: int
	var crater_depth: float
	match _archetype:
		AsteroidArchetype.C_TYPE:
			hi = PAL_P.ROCKY_ASTEROID_C_HI
			lo = PAL_P.ROCKY_ASTEROID_C_LO
			ambient = 0.04
			relief_base = 0.06
			crater_count = 5
			crater_depth = 0.7
		AsteroidArchetype.S_TYPE:
			hi = PAL_P.ROCKY_ASTEROID_S_HI
			lo = PAL_P.ROCKY_ASTEROID_S_LO
			ambient = 0.08
			relief_base = 0.12
			crater_count = 4
			crater_depth = 0.5
		AsteroidArchetype.M_TYPE:
			hi = PAL_P.ROCKY_ASTEROID_M_HI
			lo = PAL_P.ROCKY_ASTEROID_M_LO
			ambient = 0.07
			relief_base = 0.05
			crater_count = 3
			crater_depth = 0.3
		AsteroidArchetype.X_TYPE:
			hi = PAL_P.ROCKY_ASTEROID_X_HI
			lo = PAL_P.ROCKY_ASTEROID_X_LO
			ambient = 0.14
			relief_base = 0.15
			crater_count = 2
			crater_depth = 0.4
	_body_color = hi.lerp(lo, 0.5)

	_sprite.texture = TEX.make_disk_mask(TEXTURE_SIZE)
	_sprite.centered = true

	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = ASTEROID_SHADER
	_shader_mat.set_shader_parameter("u_time", 0.0)
	_shader_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_shader_mat.set_shader_parameter("u_ambient", ambient)
	_shader_mat.set_shader_parameter("u_seed", abs(_asteroid_seed) % 1023)
	_shader_mat.set_shader_parameter("u_spin_rate", _spin_rate)
	_shader_mat.set_shader_parameter("u_base_color", Vector3(1.0, 1.0, 1.0))
	_shader_mat.set_shader_parameter("u_regolith_hi", Vector3(hi.r, hi.g, hi.b))
	_shader_mat.set_shader_parameter("u_regolith_lo", Vector3(lo.r, lo.g, lo.b))
	_shader_mat.set_shader_parameter(
		"u_relief_depth", relief_base + 0.06 * (float(abs(_asteroid_seed) % 50) / 50.0)
	)
	_shader_mat.set_shader_parameter(
		"u_irregularity", 0.15 + 0.20 * (float(abs((_asteroid_seed * 7) % 100)) / 100.0)
	)
	_shader_mat.set_shader_parameter("u_crater_count", crater_count)
	_shader_mat.set_shader_parameter("u_crater_depth", crater_depth)
	_sprite.material = _shader_mat

	add_child(_sprite)


func spawn():
	_ensure_init()

	mass = randf_range(1.5e-8, 6e-8)

	var m_norm := clampf((mass - 1.5e-8) / (6e-8 - 1.5e-8), 0.0, 1.0)
	_visual_radius_px = lerpf(2.0, 10.0, pow(m_norm, 1.0 / 3.0))
	_visual_radius_px /= pow(_density_ratio, 1.0 / 3.0)

	collision_radius = _visual_radius_px * 0.7

	var mass_norm_mid := mass / 6e-8
	_spin_rate = 0.5 / clamp(mass_norm_mid, 0.25, 1.0)
	if randf() < 0.5:
		_spin_rate = -_spin_rate

	var scl := _visual_radius_px / (TEXTURE_SIZE * 0.5)
	_sprite.scale = Vector2(scl, scl)

	_shader_mat.set_shader_parameter("u_spin_rate", _spin_rate)

	var spawn_r := randf_range(2400.0, 3200.0)
	var entry_angle := randf_range(0.0, TAU)
	_pos = Vector2(cos(entry_angle), sin(entry_angle)) * spawn_r

	var v_inf := randf_range(5.0, 120.0)
	var radial_frac := randf_range(0.5, 0.95)
	var radial := -v_inf * radial_frac
	var tangential := v_inf * sqrt(1.0 - radial_frac * radial_frac)
	var dir := Vector2(cos(entry_angle), sin(entry_angle))
	var tangent := Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
	_vel = dir * radial + tangent * tangential

	position = _pos
	_asteroid_time = 0.0
	_shader_mat.set_shader_parameter("u_time", 0.0)
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
		acc += (
			gm_unit
			* pow(pl.mass, PLANET_MASS_EXPONENT)
			/ softened_r2
			* offset
			/ dist
			* PLANET_GRAVITY_SCALE
		)
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	if _shader_mat:
		_asteroid_time += delta
		_shader_mat.set_shader_parameter("u_time", _asteroid_time)
		var dir := -_pos
		if dir.length_squared() > 0.0:
			dir = dir.normalized()
		var light_vec := Vector3(dir.x, dir.y, 0.0)
		_shader_mat.set_shader_parameter("u_light_dir", light_vec)

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
