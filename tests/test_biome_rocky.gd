extends GutTest

const RockyBiome := preload("res://scripts/biomes/rocky_biome.gd")


func test_rocky_seed_features_zero_craters_clears():
	var rb := RockyBiome.new()
	rb.crater_count = 0
	rb.seed_features(42)
	assert_eq(rb._crater_lats.size(), 0, "no crater data")


func test_rocky_seed_features_creates_craters():
	var rb := RockyBiome.new()
	rb.crater_count = 5
	rb.seed_features(42)
	assert_eq(rb._crater_lats.size(), 5, "5 craters seeded")
	assert_eq(rb._crater_lons.size(), 5, "")
	assert_eq(rb._crater_sizes.size(), 5, "")
	assert_eq(rb._crater_strengths.size(), 5, "")


func test_rocky_seed_features_clamped_to_max():
	var rb := RockyBiome.new()
	rb.crater_count = 100
	rb.seed_features(42)
	assert_eq(rb._crater_lats.size(), RockyBiome.MAX_FEATURES, "clamped to MAX_FEATURES")


func test_rocky_seed_features_deterministic():
	var rb1 := RockyBiome.new()
	rb1.crater_count = 5
	rb1.seed_features(42)
	var rb2 := RockyBiome.new()
	rb2.crater_count = 5
	rb2.seed_features(42)
	for i in range(5):
		assert_almost_eq(rb1._crater_lats[i], rb2._crater_lats[i], 0.001, "lats match at %d" % i)


func test_rocky_sync_features_sets_uniforms():
	var rb := RockyBiome.new()
	rb.crater_count = 3
	rb.seed_features(42)
	var mat := ShaderMaterial.new()
	mat.shader = RockyBiome.ROCKY_SHADER
	rb.sync_features(mat)
	var count: Variant = mat.get_shader_parameter("u_crater_count")
	assert_not_null(count, "u_crater_count set")
	var pos: Variant = mat.get_shader_parameter("u_crater_pos")
	assert_not_null(pos, "u_crater_pos set")
	var sizes: Variant = mat.get_shader_parameter("u_crater_size")
	assert_not_null(sizes, "u_crater_size set")
	var strengths: Variant = mat.get_shader_parameter("u_crater_strength")
	assert_not_null(strengths, "u_crater_strength set")


func test_rocky_apply_to_shader_sets_uniforms():
	var rb := RockyBiome.new()
	rb.crater_count = 0
	var mat := ShaderMaterial.new()
	mat.shader = RockyBiome.ROCKY_SHADER
	rb.apply_to_shader(mat)
	assert_not_null(mat.get_shader_parameter("u_rocky_hi"), "u_rocky_hi set")
	assert_not_null(mat.get_shader_parameter("u_rocky_lo"), "u_rocky_lo set")
	assert_not_null(mat.get_shader_parameter("u_polar_cap_color"), "u_polar_cap_color set")
