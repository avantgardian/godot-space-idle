class_name OrbitalBody
extends Node2D

const _TEX := preload("res://scripts/util/texture_utils.gd")
const _TRAIL := preload("res://scripts/components/trail_component.gd")
const DU := preload("res://scripts/util/draw_utils.gd")
const _ATM_SHADER := preload("res://shaders/bodies/atmosphere_rim.gdshader")
const PAL := preload("res://scripts/util/planet_palette.gd")

var _sprite: Sprite2D
var _atm_sprite: Sprite2D
var _atm_mat: ShaderMaterial

@export var orbit_radius: float = 500.0
@export var orbit_period: float = 48.0
@export var start_angle: float = 0.0

var sun_mass: float = 1.0
@export var mass: float = 1.0
@export var collision_radius: float = 20.0
@export var planet_name: String = ""
@export var planet_color: Color = Color.WHITE
@export var collision_flash: float = 0.5
@export var collision_ring_color: Color = Color(1, 1, 1, 0.5)
@export var collision_ring_width: float = 2.0
@export var collision_ring_segments: int = 48
@export var collision_ring_timer: float = 1.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
@export var trail_max: int = 1200
var _gm: float = 0.0
var _trail_component: Node

@export var use_shader: bool = false
@export var planet_seed: int = 0
@export var axial_tilt_deg: float = 0.0
@export var rotation_rate: float = 0.05

@export var biome: BiomeConfig

@export var atm_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var atm_thickness_mult: float = 2.5
@export var atm_intensity: float = 1.2
@export var atm_ambient: float = 0.05

var _planet_time: float = 0.0
var _shader_mat: ShaderMaterial
var _last_light_dir := Vector2.ZERO

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
	_gm = _initial_gm()
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
	if use_shader:
		_sprite.texture = _TEX.make_disk_mask(tex_size)
	else:
		_sprite.texture = _TEX.make_circle_texture(tex_size, _get_planet_color)
	_sprite.centered = true
	add_child(_sprite)
	if use_shader and biome:
		_apply_planet_shader()
		_apply_atmosphere_shader(tex_size)


func _apply_planet_shader():
	var seed_val := planet_seed
	if seed_val == 0:
		seed_val = hash(name)
	seed_val = abs(seed_val) % 1023
	var shader := biome.get_shader()
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


func _apply_atmosphere_shader(tex_size: int):
	if atm_color.a <= 0.0:
		return
	var atm_tex_size: int = int(tex_size * atm_thickness_mult)
	if atm_tex_size < 4:
		return
	_atm_sprite = Sprite2D.new()
	_atm_sprite.texture = _TEX.make_white_square()
	_atm_sprite.centered = true
	_atm_sprite.z_index = 1
	_atm_sprite.scale = Vector2(atm_tex_size, atm_tex_size)
	add_child(_atm_sprite)
	_atm_mat = ShaderMaterial.new()
	_atm_mat.shader = _ATM_SHADER
	_atm_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_atm_mat.set_shader_parameter("u_atm_color", _TEX.vec3(atm_color))
	_atm_mat.set_shader_parameter("u_atm_intensity", atm_intensity)
	_atm_mat.set_shader_parameter("u_atm_ambient", atm_ambient)
	_atm_mat.set_shader_parameter("u_atm_thickness", 0.03)
	_atm_mat.set_shader_parameter("u_planet_radius_uv", 1.0 / atm_thickness_mult)
	_atm_sprite.material = _atm_mat


func _get_planet_texture_size() -> int:
	if biome:
		return biome.get_texture_size()
	return 32


func _get_planet_color(_t: float, _x: int, _y: int) -> Color:
	return Color.WHITE


func _reset():
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent := Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(_gm / orbit_radius)
	position = _pos
	_dead = false
	visible = true
	if _trail_component:
		_trail_component.clear()


static func sun_collision_r(mass_solar: float) -> float:
	return (128.0 + sqrt(mass_solar) * 8.0) * 0.85


func _initial_gm() -> float:
	return (
		4.0 * PI * PI * orbit_radius * orbit_radius * orbit_radius / (orbit_period * orbit_period)
	)


func get_gm() -> float:
	return _gm


func _physics_process(delta):
	if _dead:
		return

	var gm := _gm * sun_mass
	var r2 := _pos.length_squared()
	if r2 < 1.0:
		r2 = 1.0
	var r := sqrt(r2)
	var acc := -gm / r2 * _pos / r
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	if _shader_mat:
		_planet_time += delta
		_shader_mat.set_shader_parameter("u_time", _planet_time)
		var dir := -position.normalized()
		if dir.distance_squared_to(_last_light_dir) > 1e-6:
			_last_light_dir = dir
			var light_vec := Vector3(dir.x, dir.y, 0.0)
			_shader_mat.set_shader_parameter("u_light_dir", light_vec)
			if _atm_mat:
				_atm_mat.set_shader_parameter("u_light_dir", light_vec)

	var sun_r := sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		if _trail_component:
			_trail_component.fade_out()
		_dead = true
		visible = false
		collided_with_sun.emit()

	if _trail_component:
		_trail_component.record(position)
