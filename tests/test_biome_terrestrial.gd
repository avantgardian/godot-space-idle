extends GutTest

const TerrestrialBiome := preload("res://scripts/biomes/terrestrial_biome.gd")


func test_terrestrial_apply_to_shader_sets_uniforms():
	var tb := TerrestrialBiome.new()
	var mat := ShaderMaterial.new()
	mat.shader = tb.get_shader()
	tb.apply_to_shader(mat)
	assert_not_null(mat.get_shader_parameter("u_ocean_deep"), "u_ocean_deep set")
	assert_not_null(mat.get_shader_parameter("u_ocean_shallow"), "u_ocean_shallow set")
	assert_not_null(mat.get_shader_parameter("u_land_tropical"), "u_land_tropical set")
	assert_not_null(mat.get_shader_parameter("u_land_desert"), "u_land_desert set")
	assert_not_null(mat.get_shader_parameter("u_land_tundra"), "u_land_tundra set")
	assert_not_null(mat.get_shader_parameter("u_terra_ice_cap"), "u_terra_ice_cap set")
	assert_not_null(mat.get_shader_parameter("u_terra_cloud_white"), "u_terra_cloud_white set")
	assert_not_null(mat.get_shader_parameter("u_terra_specular"), "u_terra_specular set")
	assert_not_null(mat.get_shader_parameter("u_sea_level"), "u_sea_level set")
	assert_not_null(mat.get_shader_parameter("u_cloud_coverage"), "u_cloud_coverage set")
	assert_not_null(mat.get_shader_parameter("u_cloud_spin_rate"), "u_cloud_spin_rate set")
	assert_not_null(mat.get_shader_parameter("u_cloud_scale"), "u_cloud_scale set")
	assert_not_null(mat.get_shader_parameter("u_specular_power"), "u_specular_power set")
	assert_not_null(mat.get_shader_parameter("u_city_lights"), "u_city_lights set")


func test_terrestrial_default_values():
	var tb := TerrestrialBiome.new()
	assert_between(tb.sea_level, 0.0, 1.0, "sea_level in [0,1]")
	assert_gt(tb.cloud_coverage, 0.0, "cloud_coverage > 0")
	assert_gt(tb.cloud_spin_rate, 0.0, "cloud_spin_rate > 0")
