extends GutTest

const BiomeConfig := preload("res://scripts/biomes/biome_config.gd")
const GAS_GIANT_SHADER := preload("res://shaders/bodies/planet_gas_giant.gdshader")


func test_max_features_positive():
	assert_gt(BiomeConfig.MAX_FEATURES, 0, "MAX_FEATURES > 0")


func test_seed_storms_zero_count_clears_arrays():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 0, 2.0, 8.0, 3)
	assert_eq(bc._storm_lats.size(), 0, "no lats")
	assert_eq(bc._storm_lons.size(), 0, "no lons")
	assert_eq(bc._storm_sizes.size(), 0, "no sizes")
	assert_eq(bc._storm_strengths.size(), 0, "no strengths")
	assert_eq(bc._storm_kinds.size(), 0, "no kinds")


func test_seed_storms_clamped_to_max_features():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 100, 2.0, 8.0, 3)
	assert_eq(bc._storm_lats.size(), BiomeConfig.MAX_FEATURES, "clamped to MAX_FEATURES")


func test_seed_storms_produces_expected_count():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 5, 2.0, 8.0, 3)
	assert_eq(bc._storm_lats.size(), 5, "exactly 5 storms")
	assert_eq(bc._storm_lons.size(), 5, "")
	assert_eq(bc._storm_sizes.size(), 5, "")
	assert_eq(bc._storm_strengths.size(), 5, "")
	assert_eq(bc._storm_kinds.size(), 5, "")


func test_seed_storms_deterministic():
	var bc1 := BiomeConfig.new()
	bc1._seed_storms(42, 5, 2.0, 8.0, 3)
	var bc2 := BiomeConfig.new()
	bc2._seed_storms(42, 5, 2.0, 8.0, 3)
	for i in range(5):
		assert_almost_eq(bc1._storm_lats[i], bc2._storm_lats[i], 0.001, "lats match at %d" % i)
		assert_almost_eq(bc1._storm_lons[i], bc2._storm_lons[i], 0.001, "lons match at %d" % i)
		assert_almost_eq(bc1._storm_sizes[i], bc2._storm_sizes[i], 0.001, "sizes match at %d" % i)
		assert_almost_eq(
			bc1._storm_strengths[i], bc2._storm_strengths[i], 0.001, "strengths match at %d" % i
		)
		assert_eq(bc1._storm_kinds[i], bc2._storm_kinds[i], "kinds match at %d" % i)


func test_seed_storms_different_seeds_differ():
	var bc1 := BiomeConfig.new()
	bc1._seed_storms(1, 5, 2.0, 8.0, 3)
	var bc2 := BiomeConfig.new()
	bc2._seed_storms(999, 5, 2.0, 8.0, 3)
	var any_diff := false
	for i in range(5):
		if (
			not is_equal_approx(bc1._storm_lats[i], bc2._storm_lats[i])
			or not is_equal_approx(bc1._storm_lons[i], bc2._storm_lons[i])
		):
			any_diff = true
			break
	assert_true(any_diff, "different seeds produce different positions")


func test_seed_storms_lats_in_range():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 20, 2.0, 8.0, 3)
	for i in range(bc._storm_lats.size()):
		assert_between(bc._storm_lats[i], -1.4, 1.4, "lat in [-1.4, 1.4] at %d" % i)


func test_seed_storms_lons_in_range():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 20, 2.0, 8.0, 3)
	for i in range(bc._storm_lons.size()):
		assert_between(bc._storm_lons[i], -PI, PI, "lon in [-PI, PI] at %d" % i)


func test_seed_storms_sizes_in_range():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 20, 2.0, 8.0, 3)
	for i in range(bc._storm_sizes.size()):
		assert_between(
			bc._storm_sizes[i], deg_to_rad(2.0), deg_to_rad(8.0), "size in range at %d" % i
		)


func test_seed_storms_strengths_in_range():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 20, 2.0, 8.0, 3)
	for i in range(bc._storm_strengths.size()):
		assert_between(bc._storm_strengths[i], 0.4, 0.75, "strength in [0.4, 0.75] at %d" % i)


func test_seed_storms_kinds_in_range():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 20, 2.0, 8.0, 3)
	for i in range(bc._storm_kinds.size()):
		assert_between(bc._storm_kinds[i], 0, 2, "kind in [0, 2] at %d" % i)


func test_sync_storms_zero_count_sets_uniform():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 0, 2.0, 8.0, 3)
	var mat := ShaderMaterial.new()
	bc._sync_storms(mat)
	assert_eq(mat.get_shader_parameter("u_storm_count"), 0, "count 0")


func test_sync_storms_pads_to_max_features():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 3, 2.0, 8.0, 3)
	var mat := ShaderMaterial.new()
	mat.shader = GAS_GIANT_SHADER
	bc._sync_storms(mat)
	var pos: Variant = mat.get_shader_parameter("u_storm_pos")
	assert_not_null(pos, "u_storm_pos set")
	if pos:
		var v := pos as PackedVector2Array
		assert_eq(v.size(), BiomeConfig.MAX_FEATURES, "padded to MAX_FEATURES")
		assert_eq(v[0].x, bc._storm_lats[0], "first position preserved")
		assert_eq(v[3], Vector2.ZERO, "unused slot zeroed")


func test_sync_storms_sizes_padded():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 1, 2.0, 8.0, 3)
	var mat := ShaderMaterial.new()
	mat.shader = GAS_GIANT_SHADER
	bc._sync_storms(mat)
	var sizes: Variant = mat.get_shader_parameter("u_storm_size")
	assert_not_null(sizes, "u_storm_size set")
	if sizes:
		var v: PackedFloat32Array = sizes as PackedFloat32Array
		assert_almost_eq(v[0], bc._storm_sizes[0], 0.01, "first size preserved")
		assert_eq(v[1], 0.0, "unused slot zeroed")


func test_sync_storms_strengths_padded():
	var bc := BiomeConfig.new()
	bc._seed_storms(42, 2, 2.0, 8.0, 3)
	var mat := ShaderMaterial.new()
	mat.shader = GAS_GIANT_SHADER
	bc._sync_storms(mat)
	var strengths: Variant = mat.get_shader_parameter("u_storm_strength")
	assert_not_null(strengths, "u_storm_strength set")
	if strengths:
		var v: PackedFloat32Array = strengths as PackedFloat32Array
		assert_almost_eq(v[0], bc._storm_strengths[0], 0.01, "first strength preserved")
		assert_eq(v[2], 0.0, "unused slot zeroed")
