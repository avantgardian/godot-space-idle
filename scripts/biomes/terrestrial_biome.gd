class_name TerrestrialBiomeConfig
extends BiomeConfig

const TERRESTRIAL_SHADER := preload("res://shaders/bodies/planet_terrestrial.gdshader")

@export var ocean_deep: Color = Color(0.04, 0.18, 0.42, 1.0)
@export var ocean_shallow: Color = Color(0.10, 0.45, 0.65, 1.0)
@export var land_tropical: Color = Color(0.10, 0.45, 0.15, 1.0)
@export var land_desert: Color = Color(0.78, 0.65, 0.40, 1.0)
@export var land_tundra: Color = Color(0.55, 0.55, 0.40, 1.0)
@export var ice_cap: Color = Color(0.92, 0.95, 1.00, 1.0)
@export var cloud_white: Color = Color(0.95, 0.95, 0.95, 0.85)
@export var ocean_specular: Color = Color(0.95, 0.98, 1.00, 1.0)
@export var sea_level: float = 0.5
@export var ocean_shelf_depth: float = 0.15
@export var cloud_coverage: float = 0.45
@export var cloud_spin_rate: float = 0.15
@export var cloud_scale: float = 3.0
@export var specular_power: float = 64.0
@export var city_lights: float = 0.0
@export var texture_size: int = 32


func get_shader() -> Shader:
	return TERRESTRIAL_SHADER


func get_texture_size() -> int:
	return texture_size


func apply_to_shader(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("u_limb", 0.35)
	mat.set_shader_parameter("u_surface_grain_amp", 0.15)
	mat.set_shader_parameter("u_polar_cap_lat", deg_to_rad(polar_cap_lat_deg))
	mat.set_shader_parameter("u_polar_softness", polar_softness)
	mat.set_shader_parameter("u_terra_ice_cap", _vec3(ice_cap))
	mat.set_shader_parameter("u_ocean_deep", _vec3(ocean_deep))
	mat.set_shader_parameter("u_ocean_shallow", _vec3(ocean_shallow))
	mat.set_shader_parameter("u_land_tropical", _vec3(land_tropical))
	mat.set_shader_parameter("u_land_desert", _vec3(land_desert))
	mat.set_shader_parameter("u_land_tundra", _vec3(land_tundra))
	mat.set_shader_parameter("u_terra_cloud_white", _vec3(cloud_white))
	mat.set_shader_parameter("u_terra_specular", _vec3(ocean_specular))
	mat.set_shader_parameter("u_sea_level", sea_level)
	mat.set_shader_parameter("u_ocean_shelf_depth", ocean_shelf_depth)
	mat.set_shader_parameter("u_cloud_coverage", cloud_coverage)
	mat.set_shader_parameter("u_cloud_spin_rate", cloud_spin_rate)
	mat.set_shader_parameter("u_cloud_scale", cloud_scale)
	mat.set_shader_parameter("u_specular_power", specular_power)
	mat.set_shader_parameter("u_city_lights", city_lights)
