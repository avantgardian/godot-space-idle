extends GutTest

const JupiterBiome := preload("res://scripts/biomes/jupiter_biome.gd")


func test_jupiter_seed_features_fixed_great_red_spot():
	var jb := JupiterBiome.new()
	jb.storm_count = 5
	jb.seed_features(42)
	assert_eq(jb._storm_lats.size(), 5, "5 storms seeded")
	assert_almost_eq(jb._storm_lats[0], -0.5, 0.001, "GRS lat = -0.5")
	assert_almost_eq(jb._storm_lons[0], 0.0, 0.001, "GRS lon = 0.0")
	assert_almost_eq(jb._storm_sizes[0], deg_to_rad(10.0), 0.001, "GRS size = 10 deg")
	assert_almost_eq(jb._storm_strengths[0], 0.60, 0.001, "GRS strength = 0.60")
	assert_eq(jb._storm_kinds[0], JupiterBiome.STORM_RUST, "GRS is rust kind")


func test_jupiter_grs_always_first_regardless_of_seed():
	for seed_val in [1, 42, 123, 456]:
		var jb := JupiterBiome.new()
		jb.storm_count = 3
		jb.seed_features(seed_val)
		assert_almost_eq(
			jb._storm_lats[0], -0.5, 0.001, "GRS always at slot 0 (seed %d)" % seed_val
		)
		assert_eq(jb._storm_kinds[0], JupiterBiome.STORM_RUST, "GRS always rust")


func test_jupiter_remaining_storms_are_white():
	var jb := JupiterBiome.new()
	jb.storm_count = 5
	jb.seed_features(42)
	for i in range(1, jb._storm_kinds.size()):
		assert_eq(jb._storm_kinds[i], JupiterBiome.STORM_WHITE, "storm %d is white" % i)


func test_jupiter_lats_in_range():
	var jb := JupiterBiome.new()
	jb.storm_count = 10
	jb.seed_features(42)
	for i in range(1, jb._storm_lats.size()):
		assert_between(jb._storm_lats[i], -1.4, 1.4, "storm lat in range for %d" % i)
