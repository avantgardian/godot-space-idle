extends GutTest

const GasGiantBiome := preload("res://scripts/biomes/gas_giant_biome.gd")


func test_gas_giant_apply_to_shader_sets_uniforms():
	var ggb := GasGiantBiome.new()
	ggb.storm_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = ggb.get_shader()
	ggb.apply_to_shader(mat)
	assert_not_null(mat.get_shader_parameter("u_gas_band_hi"), "u_gas_band_hi set")
	assert_not_null(mat.get_shader_parameter("u_gas_band_lo"), "u_gas_band_lo set")
	assert_not_null(mat.get_shader_parameter("u_storm_rust"), "u_storm_rust set")
	assert_not_null(mat.get_shader_parameter("u_storm_white"), "u_storm_white set")
	assert_not_null(mat.get_shader_parameter("u_band_count"), "u_band_count set")
	assert_not_null(mat.get_shader_parameter("u_band_sharp"), "u_band_sharp set")
	assert_not_null(mat.get_shader_parameter("u_shear_amp"), "u_shear_amp set")
	assert_not_null(mat.get_shader_parameter("u_band_warp"), "u_band_warp set")
	assert_not_null(mat.get_shader_parameter("u_storm_stretch"), "u_storm_stretch set")


func test_gas_giant_seed_features_delegates_to_base():
	var ggb := GasGiantBiome.new()
	ggb.storm_count = 3
	ggb.seed_features(42)
	assert_eq(ggb._storm_lats.size(), 3, "3 storms seeded")


func test_gas_giant_sync_features_sets_storm_count():
	var ggb := GasGiantBiome.new()
	ggb.storm_count = 2
	ggb.seed_features(42)
	var mat := ShaderMaterial.new()
	mat.shader = ggb.get_shader()
	ggb.sync_features(mat)
	var count: Variant = mat.get_shader_parameter("u_storm_count")
	assert_not_null(count, "u_storm_count set")
