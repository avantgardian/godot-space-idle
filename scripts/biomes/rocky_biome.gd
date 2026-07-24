class_name RockyBiomeConfig
extends BiomeConfig

const ROCKY_SHADER := preload("res://shaders/bodies/planet_rocky.gdshader")

@export var rocky_hi: Color = Color(0.62, 0.58, 0.55, 1.0)
@export var rocky_lo: Color = Color(0.30, 0.27, 0.25, 1.0)
@export var polar_cap_color: Color = Color(0.90, 0.85, 0.80, 1.0)
@export var crater_count: int = 0
@export var crater_size_min_deg: float = 3.0
@export var crater_size_max_deg: float = 9.0
@export var polar_cap_lat_deg: float = 0.0
@export var polar_softness: float = 0.1
@export var texture_size: int = 32

const _MAX_CRATERS := 16

var _crater_lats: Array[float] = []
var _crater_lons: Array[float] = []
var _crater_sizes: Array[float] = []
var _crater_strengths: Array[float] = []

func get_shader() -> Shader:
	return ROCKY_SHADER

func get_texture_size() -> int:
	return texture_size

func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.35)
	mat.set_shader_parameter("u_noise_scale", 4.0)
	mat.set_shader_parameter("u_rocky_hi", _vec3(rocky_hi))
	mat.set_shader_parameter("u_rocky_lo", _vec3(rocky_lo))
	mat.set_shader_parameter("u_surface_grain_amp", 0.15)
	mat.set_shader_parameter("u_polar_cap_lat", deg_to_rad(polar_cap_lat_deg))
	mat.set_shader_parameter("u_polar_softness", polar_softness)
	mat.set_shader_parameter("u_polar_cap_color", _vec3(polar_cap_color))
	sync_features(mat)

func seed_features(seed_val: int) -> void:
	_crater_lats.clear()
	_crater_lons.clear()
	_crater_sizes.clear()
	_crater_strengths.clear()
	var count: int = clampi(crater_count, 0, _MAX_CRATERS)
	if count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 31 + 7
	for _i in range(count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(crater_size_min_deg, crater_size_max_deg))
		var strength := rng.randf_range(0.45, 0.80)
		_crater_lats.append(lat)
		_crater_lons.append(lon)
		_crater_sizes.append(size)
		_crater_strengths.append(strength)

func sync_features(mat: ShaderMaterial) -> void:
	var count := _crater_lats.size()
	mat.set_shader_parameter("u_crater_count", count)
	if count == 0:
		return
	var pos := PackedVector2Array()
	var sizes := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	pos.resize(_MAX_CRATERS)
	sizes.resize(_MAX_CRATERS)
	strengths.resize(_MAX_CRATERS)
	for i in range(_MAX_CRATERS):
		if i < count:
			pos[i] = Vector2(_crater_lats[i], _crater_lons[i])
			sizes[i] = _crater_sizes[i]
			strengths[i] = _crater_strengths[i]
		else:
			pos[i] = Vector2.ZERO
			sizes[i] = 0.0
			strengths[i] = 0.0
	mat.set_shader_parameter("u_crater_pos", pos)
	mat.set_shader_parameter("u_crater_size", sizes)
	mat.set_shader_parameter("u_crater_strength", strengths)

func _vec3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
