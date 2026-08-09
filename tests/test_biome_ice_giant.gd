extends GutTest

const IceGiantBiome := preload("res://scripts/biomes/ice_giant_biome.gd")


func test_ice_giant_apply_to_shader_sets_uniforms():
	var igb := IceGiantBiome.new()
	igb.storm_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = igb.get_shader()
	igb.apply_to_shader(mat)
	assert_not_null(mat.get_shader_parameter("u_ice_base_color"), "u_ice_base_color set")
	assert_not_null(mat.get_shader_parameter("u_ice_band_contrast"), "u_ice_band_contrast set")
	assert_not_null(mat.get_shader_parameter("u_ice_haze_color"), "u_ice_haze_color set")
	assert_not_null(mat.get_shader_parameter("u_ice_haze_strength"), "u_ice_haze_strength set")
	assert_not_null(mat.get_shader_parameter("u_ice_storm_dark"), "u_ice_storm_dark set")
	assert_not_null(mat.get_shader_parameter("u_ice_variant"), "u_ice_variant set")
	assert_not_null(mat.get_shader_parameter("u_band_count"), "u_band_count set")
	assert_not_null(mat.get_shader_parameter("u_storm_stretch"), "u_storm_stretch set")
	assert_not_null(mat.get_shader_parameter("u_storm_white"), "u_storm_white set")


func test_ice_giant_seed_features_delegates():
	var igb := IceGiantBiome.new()
	igb.storm_count = 4
	igb.seed_features(42)
	assert_eq(igb._storm_lats.size(), 4, "4 storms seeded")
