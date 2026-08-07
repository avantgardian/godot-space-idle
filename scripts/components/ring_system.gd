class_name RingSystemComponent
extends Node2D

const RING_SHADER := preload("res://shaders/bodies/ring_system.gdshader")
const PAL := preload("res://scripts/util/planet_palette.gd")
const TEX := preload("res://scripts/util/texture_utils.gd")

@export var ring_inner: float = 0.40
@export var ring_outer: float = 0.68
@export var cassini: float = 0.49
@export var cassini_width: float = 0.025
@export var encke: float = 0.55
@export var encke_width: float = 0.006
@export var shadow_strength: float = 0.4
@export var ring_bright: Color = Color(0.78, 0.68, 0.45, 1.0)
@export var ring_dark: Color = Color(0.20, 0.15, 0.08, 1.0)
@export var ring_seed: int = -1
@export var ring_size: float = 256.0
@export var ring_aspect: float = 0.30

var _ring_sprite_back: Sprite2D
var _ring_sprite_front: Sprite2D
var _ring_mat_back: ShaderMaterial
var _ring_mat_front: ShaderMaterial
var _ring_rotation: float = 0.0
var _cos_ring_rot: float = 1.0
var _sin_ring_rot: float = 0.0
var _last_light_dir := Vector3(1.0, 0.0, 0.0)


func _ready():
	var parent := get_parent()

	var seed_val := ring_seed
	if seed_val < 0:
		seed_val = parent.planet_seed
	if seed_val == 0:
		push_error("%s: ring_seed is 0 — set an explicit seed" % name)
	seed_val = abs(seed_val) % 1023

	var tilt_deg: float = parent.axial_tilt_deg
	_ring_rotation = deg_to_rad(tilt_deg)
	_cos_ring_rot = cos(-_ring_rotation)
	_sin_ring_rot = sin(-_ring_rotation)

	var tex := TEX.make_white_square()
	var ring_scale := Vector2(ring_size, ring_size * ring_aspect)

	_ring_sprite_back = Sprite2D.new()
	_ring_sprite_back.texture = tex
	_ring_sprite_back.centered = true
	_ring_sprite_back.z_index = -1
	_ring_sprite_back.scale = ring_scale
	_ring_sprite_back.rotation = _ring_rotation
	_ring_mat_back = _make_ring_material(-1, seed_val)
	_ring_sprite_back.material = _ring_mat_back
	add_child(_ring_sprite_back)

	_ring_sprite_front = Sprite2D.new()
	_ring_sprite_front.texture = tex
	_ring_sprite_front.centered = true
	_ring_sprite_front.z_index = 1
	_ring_sprite_front.scale = ring_scale
	_ring_sprite_front.rotation = _ring_rotation
	_ring_mat_front = _make_ring_material(1, seed_val)
	_ring_sprite_front.material = _ring_mat_front
	add_child(_ring_sprite_front)


func _make_ring_material(half_mask: int, seed_val: int) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	mat.set_shader_parameter("u_ring_inner", ring_inner)
	mat.set_shader_parameter("u_ring_outer", ring_outer)
	mat.set_shader_parameter("u_cassini", cassini)
	mat.set_shader_parameter("u_cassini_width", cassini_width)
	mat.set_shader_parameter("u_encke", encke)
	mat.set_shader_parameter("u_encke_width", encke_width)
	mat.set_shader_parameter("u_ring_seed", seed_val)
	mat.set_shader_parameter("u_ring_bright", Vector3(ring_bright.r, ring_bright.g, ring_bright.b))
	mat.set_shader_parameter("u_ring_dark", Vector3(ring_dark.r, ring_dark.g, ring_dark.b))
	mat.set_shader_parameter("u_shadow_strength", shadow_strength)
	mat.set_shader_parameter("u_half_mask", half_mask)
	return mat


func _physics_process(_delta):
	var parent := get_parent()
	if not parent:
		return
	var dir: Vector2 = -parent.position.normalized()
	var lx := dir.x * _cos_ring_rot - dir.y * _sin_ring_rot
	var ly := dir.x * _sin_ring_rot + dir.y * _cos_ring_rot
	var ring_light := Vector3(lx, ly, 0.0)
	if ring_light.distance_squared_to(_last_light_dir) > 1e-6:
		_last_light_dir = ring_light
		if _ring_mat_back:
			_ring_mat_back.set_shader_parameter("u_light_dir", ring_light)
		if _ring_mat_front:
			_ring_mat_front.set_shader_parameter("u_light_dir", ring_light)
