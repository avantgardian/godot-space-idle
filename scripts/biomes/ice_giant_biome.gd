class_name IceGiantBiomeConfig
extends BiomeConfig

const ICE_GIANT_SHADER := preload("res://shaders/bodies/planet_ice_giant.gdshader")

const STORM_WHITE: int = 1
const STORM_DARK: int = 2

@export var base_color: Color = Color(0.30, 0.65, 0.85, 1.0)
@export var haze_color: Color = Color(0.85, 0.92, 1.00, 1.0)
@export var storm_dark: Color = Color(0.04, 0.10, 0.30, 1.0)
@export var storm_white: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var ice_variant: int = 0
@export var ice_band_contrast: float = 0.03
@export var ice_haze_strength: float = 0.0
@export var band_count: int = 6
@export var storm_count: int = 0
@export var storm_size_min_deg: float = 2.0
@export var storm_size_max_deg: float = 8.0
@export var storm_stretch: float = 3.0
@export var texture_size: int = 32


func get_shader() -> Shader:
	return ICE_GIANT_SHADER


func get_texture_size() -> int:
	return texture_size


func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.30)
	mat.set_shader_parameter("u_ice_base_color", base_color)
	mat.set_shader_parameter("u_ice_band_contrast", ice_band_contrast)
	mat.set_shader_parameter("u_ice_haze_color", haze_color)
	mat.set_shader_parameter("u_ice_haze_strength", ice_haze_strength)
	mat.set_shader_parameter("u_ice_storm_dark", storm_dark)
	mat.set_shader_parameter("u_ice_variant", ice_variant)
	mat.set_shader_parameter("u_band_count", band_count)
	mat.set_shader_parameter("u_storm_stretch", storm_stretch)
	mat.set_shader_parameter("u_storm_white", storm_white)
	sync_features(mat)


func seed_features(seed_val: int) -> void:
	_seed_storms(seed_val, storm_count, storm_size_min_deg, storm_size_max_deg, 2)


func sync_features(mat: ShaderMaterial) -> void:
	_sync_storms(mat)
