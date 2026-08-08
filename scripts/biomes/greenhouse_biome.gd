class_name GreenhouseBiomeConfig
extends BiomeConfig

const GREENHOUSE_SHADER := preload("res://shaders/bodies/planet_greenhouse.gdshader")

@export var cloud_hi: Color = Color(0.95, 0.85, 0.55, 1.0)
@export var cloud_lo: Color = Color(0.65, 0.45, 0.20, 1.0)
@export var lava_color: Color = Color(0.60, 0.15, 0.05, 1.0)
@export var cloud_swirl_amp: float = 0.15
@export var cloud_swirl_freq: float = 6.0
@export var cloud_contrast: float = 0.6
@export var limb_brighten: float = 0.0
@export var surface_lava_leak: float = 0.0
@export var texture_size: int = 32


func get_shader() -> Shader:
	return GREENHOUSE_SHADER


func get_texture_size() -> int:
	return texture_size


func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.35)
	mat.set_shader_parameter("u_venus_cloud_hi", cloud_hi)
	mat.set_shader_parameter("u_venus_cloud_lo", cloud_lo)
	mat.set_shader_parameter("u_cloud_swirl_amp", cloud_swirl_amp)
	mat.set_shader_parameter("u_cloud_swirl_freq", cloud_swirl_freq)
	mat.set_shader_parameter("u_cloud_contrast", cloud_contrast)
	mat.set_shader_parameter("u_limb_brighten", limb_brighten)
	mat.set_shader_parameter("u_surface_lava_leak", surface_lava_leak)
	mat.set_shader_parameter("u_lava_color", lava_color)
