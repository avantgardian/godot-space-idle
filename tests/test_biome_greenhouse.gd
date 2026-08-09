extends GutTest

const GreenhouseBiome := preload("res://scripts/biomes/greenhouse_biome.gd")


func test_greenhouse_apply_to_shader_sets_uniforms():
	var gb := GreenhouseBiome.new()
	var mat := ShaderMaterial.new()
	mat.shader = gb.get_shader()
	gb.apply_to_shader(mat)
	assert_not_null(mat.get_shader_parameter("u_venus_cloud_hi"), "u_venus_cloud_hi set")
	assert_not_null(mat.get_shader_parameter("u_venus_cloud_lo"), "u_venus_cloud_lo set")
	assert_not_null(mat.get_shader_parameter("u_cloud_swirl_amp"), "u_cloud_swirl_amp set")
	assert_not_null(mat.get_shader_parameter("u_cloud_swirl_freq"), "u_cloud_swirl_freq set")
	assert_not_null(mat.get_shader_parameter("u_cloud_contrast"), "u_cloud_contrast set")
	assert_not_null(mat.get_shader_parameter("u_limb_brighten"), "u_limb_brighten set")
	assert_not_null(mat.get_shader_parameter("u_surface_lava_leak"), "u_surface_lava_leak set")
	assert_not_null(mat.get_shader_parameter("u_lava_color"), "u_lava_color set")


func test_greenhouse_default_values():
	var gb := GreenhouseBiome.new()
	assert_gt(gb.cloud_swirl_freq, 0.0, "swirl freq > 0")
	assert_gt(gb.cloud_contrast, 0.0, "contrast > 0")
