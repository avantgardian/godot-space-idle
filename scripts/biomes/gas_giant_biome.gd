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


func get_shader() -> Shader:
	return GAS_GIANT_SHADER


func get_texture_size() -> int:
	return texture_size


func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.35)
	mat.set_shader_parameter("u_gas_band_hi", band_hi)
	mat.set_shader_parameter("u_gas_band_lo", band_lo)
	mat.set_shader_parameter("u_storm_rust", storm_rust)
	mat.set_shader_parameter("u_storm_white", storm_white)
	mat.set_shader_parameter("u_band_count", band_count)
	mat.set_shader_parameter("u_band_sharp", band_sharp)
	mat.set_shader_parameter("u_shear_amp", shear_amp)
	mat.set_shader_parameter("u_band_warp", band_warp)
	mat.set_shader_parameter("u_storm_stretch", storm_stretch)
	sync_features(mat)


func seed_features(seed_val: int) -> void:
	_seed_storms(seed_val, storm_count, storm_size_min_deg, storm_size_max_deg, 2)


func sync_features(mat: ShaderMaterial) -> void:
	_sync_storms(mat)
