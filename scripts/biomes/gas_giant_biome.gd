class_name GasGiantBiomeConfig
extends BiomeConfig

const GAS_GIANT_SHADER := preload("res://shaders/bodies/planet_gas_giant.gdshader")

const STORM_RUST: int = 0
const STORM_WHITE: int = 1

@export var band_hi: Color = Color(0.88, 0.78, 0.55, 1.0)
@export var band_lo: Color = Color(0.50, 0.32, 0.18, 1.0)
@export var storm_rust: Color = Color(0.85, 0.30, 0.20, 1.0)
@export var storm_white: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var band_count: int = 12
@export var band_sharp: float = 0.15
@export var shear_amp: float = 0.10
@export var band_warp: float = 0.05
@export var storm_count: int = 0
@export var storm_size_min_deg: float = 2.0
@export var storm_size_max_deg: float = 8.0
@export var storm_stretch: float = 3.0
@export var texture_size: int = 32

const _MAX_STORMS := 16

var _storm_lats: Array[float] = []
var _storm_lons: Array[float] = []
var _storm_sizes: Array[float] = []
var _storm_strengths: Array[float] = []
var _storm_kinds: Array[int] = []

func get_shader() -> Shader:
	return GAS_GIANT_SHADER

func get_texture_size() -> int:
	return texture_size

func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.35)
	mat.set_shader_parameter("u_gas_band_hi", _vec3(band_hi))
	mat.set_shader_parameter("u_gas_band_lo", _vec3(band_lo))
	mat.set_shader_parameter("u_storm_rust", _vec3(storm_rust))
	mat.set_shader_parameter("u_storm_white", _vec3(storm_white))
	mat.set_shader_parameter("u_band_count", band_count)
	mat.set_shader_parameter("u_band_sharp", band_sharp)
	mat.set_shader_parameter("u_shear_amp", shear_amp)
	mat.set_shader_parameter("u_band_warp", band_warp)
	mat.set_shader_parameter("u_storm_stretch", storm_stretch)
	sync_features(mat)

func seed_features(seed_val: int) -> void:
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	var count: int = clampi(storm_count, 0, _MAX_STORMS)
	if count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 53 + 11
	for _i in range(count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(storm_size_min_deg, storm_size_max_deg))
		var strength := rng.randf_range(0.4, 0.75)
		var kind: int = rng.randi_range(0, 1)
		_storm_lats.append(lat)
		_storm_lons.append(lon)
		_storm_sizes.append(size)
		_storm_strengths.append(strength)
		_storm_kinds.append(kind)

func sync_features(mat: ShaderMaterial) -> void:
	var count := _storm_lats.size()
	mat.set_shader_parameter("u_storm_count", count)
	if count == 0:
		return
	var pos := PackedVector2Array()
	var sizes := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	var kinds := PackedInt32Array()
	pos.resize(_MAX_STORMS)
	sizes.resize(_MAX_STORMS)
	strengths.resize(_MAX_STORMS)
	kinds.resize(_MAX_STORMS)
	for i in range(_MAX_STORMS):
		if i < count:
			pos[i] = Vector2(_storm_lats[i], _storm_lons[i])
			sizes[i] = _storm_sizes[i]
			strengths[i] = _storm_strengths[i]
			kinds[i] = _storm_kinds[i]
		else:
			pos[i] = Vector2.ZERO
			sizes[i] = 0.0
			strengths[i] = 0.0
			kinds[i] = 0
	mat.set_shader_parameter("u_storm_pos", pos)
	mat.set_shader_parameter("u_storm_size", sizes)
	mat.set_shader_parameter("u_storm_strength", strengths)
	mat.set_shader_parameter("u_storm_kind", kinds)

func _vec3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
