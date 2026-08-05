extends OrbitalBody

const RING_SHADER := preload("res://shaders/bodies/ring_system.gdshader")

var _ring_sprite_back: Sprite2D
var _ring_sprite_front: Sprite2D
var _ring_mat_back: ShaderMaterial
var _ring_mat_front: ShaderMaterial
var _ring_rotation: float = 0.0
var _cos_ring_rot: float = 1.0
var _sin_ring_rot: float = 0.0


func _ready():
	biome = preload("res://resources/biomes/gas_giant_saturn.tres")
	planet_name = "Saturn"
	planet_color = PAL.SATURN_BAND_HI
	collision_flash = 1.8
	collision_ring_color = Color(0.8, 0.7, 0.4, 0.8)
	collision_ring_width = 5.0
	collision_ring_segments = 88
	collision_ring_timer = 2.2
	use_shader = true
	planet_seed = 436
	rotation_rate = 0.35
	super()
	_generate_ring()


func _generate_ring():
	var tex := _TEX.make_white_square()

	if planet_seed == 0:
		push_error(
			"%s: planet_seed is 0 — set an explicit seed for stable procedural generation" % name
		)
	var seed_val: int = abs(planet_seed) % 1023

	_ring_rotation = deg_to_rad(axial_tilt_deg)
	_cos_ring_rot = cos(-_ring_rotation)
	_sin_ring_rot = sin(-_ring_rotation)

	_ring_sprite_back = Sprite2D.new()
	_ring_sprite_back.texture = tex
	_ring_sprite_back.centered = true
	_ring_sprite_back.z_index = -1
	_ring_sprite_back.scale = Vector2(256, 76.8)
	_ring_sprite_back.rotation = _ring_rotation
	_ring_mat_back = _make_ring_material(-1, seed_val)
	_ring_sprite_back.material = _ring_mat_back
	add_child(_ring_sprite_back)

	_ring_sprite_front = Sprite2D.new()
	_ring_sprite_front.texture = tex
	_ring_sprite_front.centered = true
	_ring_sprite_front.z_index = 1
	_ring_sprite_front.scale = Vector2(256, 76.8)
	_ring_sprite_front.rotation = _ring_rotation
	_ring_mat_front = _make_ring_material(1, seed_val)
	_ring_sprite_front.material = _ring_mat_front
	add_child(_ring_sprite_front)


func _make_ring_material(half_mask: int, seed_val: int) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	mat.set_shader_parameter("u_ring_inner", 0.40)
	mat.set_shader_parameter("u_ring_outer", 0.68)
	mat.set_shader_parameter("u_cassini", 0.49)
	mat.set_shader_parameter("u_cassini_width", 0.025)
	mat.set_shader_parameter("u_encke", 0.55)
	mat.set_shader_parameter("u_encke_width", 0.006)
	mat.set_shader_parameter("u_ring_seed", seed_val)
	mat.set_shader_parameter(
		"u_ring_bright",
		Vector3(PAL.RING_SATURN_TAN.r, PAL.RING_SATURN_TAN.g, PAL.RING_SATURN_TAN.b)
	)
	mat.set_shader_parameter(
		"u_ring_dark",
		Vector3(PAL.RING_SATURN_DARK.r, PAL.RING_SATURN_DARK.g, PAL.RING_SATURN_DARK.b)
	)
	mat.set_shader_parameter("u_shadow_strength", 0.4)
	mat.set_shader_parameter("u_half_mask", half_mask)
	return mat


func _physics_process(delta):
	super(delta)
	_update_ring_light()


func _update_ring_light():
	var dir := -position.normalized()
	var lx := dir.x * _cos_ring_rot - dir.y * _sin_ring_rot
	var ly := dir.x * _sin_ring_rot + dir.y * _cos_ring_rot
	var ring_light := Vector3(lx, ly, 0.0)
	if _ring_mat_back:
		_ring_mat_back.set_shader_parameter("u_light_dir", ring_light)
	if _ring_mat_front:
		_ring_mat_front.set_shader_parameter("u_light_dir", ring_light)
