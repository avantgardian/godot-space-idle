class_name OrbitalBody
extends Node2D

signal collided_with_sun(body: Node2D)

enum PlanetGravityMode {
	REALISTIC,
	EXAGGERATED,
}

const _TEX: GDScript = preload("res://scripts/util/texture_utils.gd")
const _TRAIL: GDScript = preload("res://scripts/components/trail_component.gd")
const DU: GDScript = preload("res://scripts/util/draw_utils.gd")
const _ATM_SHADER: Shader = preload("res://shaders/bodies/atmosphere_rim.gdshader")
const PAL: GDScript = preload("res://scripts/util/planet_palette.gd")
const _COLLISION: GDScript = preload("res://scripts/util/collision_profile.gd")
const PLANET_GRAVITY_SCALE: float = 5.0
const PLANET_MASS_EXPONENT: float = 0.3
const PLANET_SOFTENING: float = 150.0
const OSCULATING_UPDATE_INTERVAL: float = 0.5

static var _bench_total_us: int = 0
static var _bench_samples: int = 0

@export var orbit_radius: float = 500.0
@export var orbit_period: float = 48.0
@export var start_angle: float = 0.0
@export var mass: float = 1.0
@export var collision_radius: float = 20.0
@export var planet_name: String = ""
@export var planet_color: Color = Color.WHITE
@export var collision_profile: CollisionProfile
@export var trail_max: int = 600
@export var use_shader: bool = false
@export var planet_seed: int = 0
@export var axial_tilt_deg: float = 0.0
@export var rotation_rate: float = 0.05
@export var biome: BiomeConfig
@export var atm_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var atm_thickness_mult: float = 2.5
@export var atm_intensity: float = 1.2
@export var atm_ambient: float = 0.05

var sun_mass: float = 1.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
var _gm: float = 0.0
var _trail_component: TrailComponent
var _sprite: Sprite2D
var _atm_sprite: Sprite2D
var _atm_mat: ShaderMaterial
var _planet_time: float = 0.0
var _shader_mat: ShaderMaterial
var _last_light_dir: Vector2 = Vector2.ZERO
var _peer_data: Array[Dictionary] = []
var _planet_gravity_enabled: bool = false
var _planet_gravity_mode: PlanetGravityMode = PlanetGravityMode.REALISTIC
var _planet_gravity_scale: float = 1.0
var _planet_softening: float = PLANET_SOFTENING
var _reference_gm: float = 0.0
var _initial_orbit_radius: float = 0.0
var _initial_orbit_period: float = 0.0
var _osculating_timer: float = 0.0
var _last_sun_mass_for_osculating: float = 1.0


func is_dead() -> bool:
	return _dead


func disable() -> void:
	if _trail_component:
		_trail_component.fade_out()
	_dead = true
	visible = false


func set_peer_data(data: Array[Dictionary]) -> void:
	_peer_data = data


func configure_planet_gravity(
	enabled: bool,
	mode: PlanetGravityMode,
	gravity_scale: float,
	softening: float,
	reference_gm: float
) -> void:
	_planet_gravity_enabled = enabled
	_planet_gravity_mode = mode
	_planet_gravity_scale = gravity_scale
	_planet_softening = softening
	_reference_gm = reference_gm


static func get_planet_gravity_bench_avg_us() -> float:
	if _bench_samples == 0:
		return 0.0
	return float(_bench_total_us) / float(_bench_samples)


static func reset_planet_gravity_bench() -> void:
	_bench_total_us = 0
	_bench_samples = 0


static func reference_gm_default() -> float:
	return kepler_gm(350.0, 25.0)


func get_vel() -> Vector2:
	return _vel


func set_vel(v: Vector2) -> void:
	_vel = v


func _ready() -> void:
	_gm = _initial_gm()
	_initial_orbit_radius = orbit_radius
	_initial_orbit_period = orbit_period
	_last_sun_mass_for_osculating = sun_mass
	_generate_texture()
	_reset()


func setup_trail(color: Color) -> void:
	@warning_ignore("unsafe_cast")
	_trail_component = _TRAIL.new() as TrailComponent
	@warning_ignore("unsafe_method_access")
	var head: Color = DU.trail_head(color)
	@warning_ignore("unsafe_method_access")
	var tail: Color = DU.trail_tail(color)
	_trail_component.setup(tail, head, 1.5, trail_max)
	add_child(_trail_component)


func _generate_texture() -> void:
	var tex_size: int = _get_planet_texture_size()
	_sprite = Sprite2D.new()
	if use_shader:
		@warning_ignore("unsafe_method_access")
		_sprite.texture = _TEX.make_disk_mask(tex_size)
	else:
		@warning_ignore("unsafe_method_access")
		_sprite.texture = _TEX.make_circle_texture(tex_size, _get_planet_color)
	_sprite.centered = true
	add_child(_sprite)
	if use_shader and biome:
		_apply_planet_shader()
		_apply_atmosphere_shader(tex_size)


func _apply_planet_shader() -> void:
	if planet_seed == 0:
		push_error(
			"%s: planet_seed is 0 — set an explicit seed for stable procedural generation" % name
		)
	var seed_val: int = abs(planet_seed) % 1023
	var shader: Shader = biome.get_shader()
	if not shader:
		return
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("u_time", 0.0)
	_shader_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_shader_mat.set_shader_parameter("u_ambient", 0.06)
	_shader_mat.set_shader_parameter("u_night_rim", 0.4)
	_shader_mat.set_shader_parameter("u_axial_tilt", deg_to_rad(axial_tilt_deg))
	_shader_mat.set_shader_parameter("u_spin_rate", rotation_rate)
	_shader_mat.set_shader_parameter("u_seed", seed_val)
	biome.seed_features(seed_val)
	biome.apply_to_shader(_shader_mat)
	_sprite.material = _shader_mat


func _apply_atmosphere_shader(tex_size: int) -> void:
	if atm_color.a <= 0.0:
		return
	var atm_tex_size: int = int(tex_size * atm_thickness_mult)
	if atm_tex_size < 4:
		return
	_atm_sprite = Sprite2D.new()
	@warning_ignore("unsafe_method_access")
	_atm_sprite.texture = _TEX.make_white_square()
	_atm_sprite.centered = true
	_atm_sprite.z_index = 1
	_atm_sprite.scale = Vector2(atm_tex_size, atm_tex_size)
	add_child(_atm_sprite)
	_atm_mat = ShaderMaterial.new()
	_atm_mat.shader = _ATM_SHADER
	_atm_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_atm_mat.set_shader_parameter("u_atm_color", atm_color)
	_atm_mat.set_shader_parameter("u_atm_intensity", atm_intensity)
	_atm_mat.set_shader_parameter("u_atm_ambient", atm_ambient)
	_atm_mat.set_shader_parameter("u_atm_thickness", 0.03)
	# Slight overlap (3%) with planet disk to hide the 1px AA gap between
	# the planet's edge_aa and the atmosphere inner rim that otherwise
	# shows as a thin black outline on bright day sides (Venus/Uranus/Neptune).
	_atm_mat.set_shader_parameter("u_planet_radius_uv", 1.0 / atm_thickness_mult * 0.97)
	_atm_sprite.material = _atm_mat


func _get_planet_texture_size() -> int:
	if biome:
		return biome.get_texture_size()
	return 32


func _get_planet_color(_t: float, _x: int, _y: int) -> Color:
	return Color.WHITE


func _reset() -> void:
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent: Vector2 = Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(_gm / orbit_radius)
	position = _pos
	_dead = false
	visible = true
	if _trail_component:
		_trail_component.clear()


static func kepler_gm(radius: float, period: float) -> float:
	return 4.0 * PI * PI * radius * radius * radius / (period * period)


static func sun_collision_r(mass_solar: float) -> float:
	return (128.0 + sqrt(mass_solar) * 8.0) * 0.85


func _initial_gm() -> float:
	return kepler_gm(orbit_radius, orbit_period)


func get_gm() -> float:
	return _gm


func get_initial_orbit_radius() -> float:
	return _initial_orbit_radius


func get_initial_orbit_period() -> float:
	return _initial_orbit_period


func recompute_osculating_elements() -> void:
	if _dead:
		return
	var r: float = _pos.length()
	if r < 1.0:
		return
	var v2: float = _vel.length_squared()
	var mu: float = _gm * sun_mass
	if mu <= 0.0:
		return
	var energy: float = v2 * 0.5 - mu / r
	if energy < 0.0:
		var a: float = -mu / (2.0 * energy)
		if a > 0.0 and is_finite(a):
			orbit_radius = a
			orbit_period = 2.0 * PI * sqrt(a * a * a / mu)
	else:
		orbit_radius = r
		orbit_period = INF


func _physics_process(delta: float) -> void:
	if _dead:
		return

	var gm: float = _gm * sun_mass
	var r2: float = _pos.length_squared()
	if r2 < 1.0:
		r2 = 1.0
	var r: float = sqrt(r2)
	var acc: Vector2 = -gm / r2 * _pos / r
	if _planet_gravity_enabled and not _peer_data.is_empty() and _reference_gm > 0.0:
		var bench_start: int = Time.get_ticks_usec()
		for peer: Dictionary in _peer_data:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			var peer_pos: Vector2 = peer.pos as Vector2
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			var peer_mass: float = peer.mass as float
			if peer_mass <= 0.0:
				continue
			var offset: Vector2 = peer_pos - _pos
			var dist_sq: float = offset.length_squared()
			if dist_sq < 1e-6:
				continue
			var dist: float = sqrt(dist_sq)
			var softened_r2: float = dist_sq + _planet_softening * _planet_softening
			if _planet_gravity_mode == PlanetGravityMode.REALISTIC:
				acc += (
					_reference_gm * peer_mass * _planet_gravity_scale / softened_r2 * offset / dist
				)
			else:
				acc += (
					_reference_gm
					* pow(peer_mass, PLANET_MASS_EXPONENT)
					/ softened_r2
					* offset
					/ dist
					* PLANET_GRAVITY_SCALE
					* _planet_gravity_scale
				)
		var bench_end: int = Time.get_ticks_usec()
		_bench_total_us += bench_end - bench_start
		_bench_samples += 1
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	if _shader_mat:
		_planet_time += delta
		_shader_mat.set_shader_parameter("u_time", _planet_time)
		var dir: Vector2 = -position.normalized()
		if dir.distance_squared_to(_last_light_dir) > 1e-6:
			_last_light_dir = dir
			var light_vec: Vector3 = Vector3(dir.x, dir.y, 0.0)
			_shader_mat.set_shader_parameter("u_light_dir", light_vec)
			if _atm_mat:
				_atm_mat.set_shader_parameter("u_light_dir", light_vec)

	var sun_r: float = sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		if _trail_component:
			_trail_component.fade_out()
		_dead = true
		visible = false
		collided_with_sun.emit(self)

	if _trail_component:
		_trail_component.record(position)

	# Keep osculating orbit values in sync with dynamical state.
	# Immediate on sun mass change (affects mu), throttled for N-body drift.
	var sun_changed: bool = not is_equal_approx(sun_mass, _last_sun_mass_for_osculating)
	if sun_changed:
		recompute_osculating_elements()
		_last_sun_mass_for_osculating = sun_mass
		_osculating_timer = 0.0
	else:
		_osculating_timer += delta
		if _osculating_timer >= OSCULATING_UPDATE_INTERVAL:
			_osculating_timer = 0.0
			recompute_osculating_elements()
