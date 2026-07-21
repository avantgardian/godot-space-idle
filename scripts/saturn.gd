extends OrbitalBody

const RING_SHADER := preload("res://shaders/ring_system.gdshader")

var _ring_sprite_back: Sprite2D
var _ring_sprite_front: Sprite2D
var _ring_mat_back: ShaderMaterial
var _ring_mat_front: ShaderMaterial
var _ring_rotation: float = 0.0
var _cos_ring_rot: float = 1.0
var _sin_ring_rot: float = 0.0

func _ready():
	planet_name = "Saturn"
	planet_color = Color(0.8, 0.7, 0.4)
	collision_flash = 1.8
	collision_ring_color = Color(0.8, 0.7, 0.4, 0.8)
	collision_ring_width = 5.0
	collision_ring_segments = 88
	collision_ring_timer = 2.2
	use_shader = true
	planet_type = &"gas_giant"
	planet_color = PAL.SATURN_BAND_HI
	rotation_rate = 0.35
	band_count = 10
	band_sharp = 0.20
	shear_amp = 0.07
	band_warp = 0.05
	storm_count = 0
	storm_stretch = 2.0
	super()
	_generate_ring()

func _get_planet_texture_size() -> int:
	return 88

func _get_gas_band_hi() -> Color:
	return PAL.SATURN_BAND_HI

func _get_gas_band_lo() -> Color:
	return PAL.SATURN_BAND_LO

func _generate_ring():
	var ring_tex_size: int = 256
	var image := Image.create(ring_tex_size, ring_tex_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	var tex := ImageTexture.create_from_image(image)

	var seed_val := planet_seed
	if seed_val == 0:
		seed_val = hash(name)
	seed_val = abs(seed_val) % 1023

	_ring_rotation = deg_to_rad(axial_tilt_deg)
	_cos_ring_rot = cos(-_ring_rotation)
	_sin_ring_rot = sin(-_ring_rotation)

	# Back half — behind the planet.
	_ring_sprite_back = Sprite2D.new()
	_ring_sprite_back.texture = tex
	_ring_sprite_back.centered = true
	_ring_sprite_back.z_index = -1
	_ring_sprite_back.scale = Vector2(1.0, 0.30)
	_ring_sprite_back.rotation = _ring_rotation
	_ring_mat_back = _make_ring_material(-1, seed_val)
	_ring_sprite_back.material = _ring_mat_back
	add_child(_ring_sprite_back)

	# Front half — in front of the planet.
	_ring_sprite_front = Sprite2D.new()
	_ring_sprite_front.texture = tex
	_ring_sprite_front.centered = true
	_ring_sprite_front.z_index = 1
	_ring_sprite_front.scale = Vector2(1.0, 0.30)
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
	mat.set_shader_parameter("u_ring_bright", _TEX.vec3(PAL.RING_SATURN_TAN))
	mat.set_shader_parameter("u_ring_dark", _TEX.vec3(PAL.RING_SATURN_DARK))
	mat.set_shader_parameter("u_shadow_strength", 0.4)
	mat.set_shader_parameter("u_half_mask", half_mask)
	return mat

func _process(delta):
	super(delta)
	_update_ring_light(_ring_mat_back)
	_update_ring_light(_ring_mat_front)

func _update_ring_light(mat: ShaderMaterial):
	if not mat:
		return
	var dir := -position
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
	var lx := dir.x * _cos_ring_rot - dir.y * _sin_ring_rot
	var ly := dir.x * _sin_ring_rot + dir.y * _cos_ring_rot
	mat.set_shader_parameter("u_light_dir", Vector3(lx, ly, 0.0))
