class_name OrbitalBody
extends Node2D

const _TEX := preload("res://scripts/texture_utils.gd")
const _TRAIL := preload("res://scripts/trail_component.gd")
const DU := preload("res://scripts/draw_utils.gd")
const _PLANET_SHADER := preload("res://shaders/planet_surface.gdshader")
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

@export var use_shader: bool = false
@export var planet_type: StringName = &""
@export var planet_seed: int = 0
@export var axial_tilt_deg: float = 0.0
@export var rotation_rate: float = 0.05

var _planet_time: float = 0.0
var _shader_mat: ShaderMaterial

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
	if use_shader:
		_sprite.texture = _make_white_disk_mask(tex_size)
	else:
		_sprite.texture = _TEX.make_circle_texture(tex_size, _get_planet_color)
	_sprite.centered = true
	add_child(_sprite)
	if use_shader:
		_apply_planet_shader()

func _make_white_disk_mask(size: int) -> ImageTexture:
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
				var alpha := 1.0
				if t > 0.95:
					alpha = 1.0 - (t - 0.95) / 0.05
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _apply_planet_shader():
	var seed_val := planet_seed
	if seed_val == 0:
		seed_val = hash(name)
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = _PLANET_SHADER
	_shader_mat.set_shader_parameter("u_time", 0.0)
	_shader_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_shader_mat.set_shader_parameter("u_ambient", 0.06)
	_shader_mat.set_shader_parameter("u_night_rim", 0.4)
	_shader_mat.set_shader_parameter("u_limb", 0.35)
	_shader_mat.set_shader_parameter("u_axial_tilt", deg_to_rad(axial_tilt_deg))
	_shader_mat.set_shader_parameter("u_spin_rate", rotation_rate)
	_shader_mat.set_shader_parameter("u_seed", seed_val)
	var bc := _get_shader_base_color()
	_shader_mat.set_shader_parameter("u_base_color", Vector3(bc.r, bc.g, bc.b))
	_shader_mat.set_shader_parameter("u_noise_scale", 4.0)
	_shader_mat.set_shader_parameter("u_noise_amp", 0.15)
	_sprite.material = _shader_mat

func _get_shader_base_color() -> Color:
	var pc = get("planet_color")
	if pc is Color:
		return pc
	return Color.WHITE

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

	if _shader_mat:
		_planet_time += delta
		_shader_mat.set_shader_parameter("u_time", _planet_time)
		var dir := -position
		if dir.length_squared() > 0.0:
			dir = dir.normalized()
		_shader_mat.set_shader_parameter("u_light_dir", Vector3(dir.x, dir.y, 0.0))

	var sun_r := sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		if _trail_component:
			_trail_component.fade_out()
		_dead = true
		visible = false
		collided_with_sun.emit()

	if _trail_component:
		_trail_component.record(position)
