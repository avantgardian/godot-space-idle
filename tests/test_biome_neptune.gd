extends GutTest

const NeptuneBiome := preload("res://scripts/biomes/neptune_biome.gd")


func test_neptune_seeds_great_dark_spot():
	var nb := NeptuneBiome.new()
	nb.seed_features(42)
	assert_true(nb._storm_lats.size() >= 2, "at least 2 storms")
	assert_almost_eq(nb._storm_lats[0], -0.3, 0.001, "GDS lat = -0.3")
	assert_almost_eq(nb._storm_lons[0], 0.0, 0.001, "GDS lon = 0.0")
	assert_almost_eq(nb._storm_sizes[0], deg_to_rad(9.0), 0.001, "GDS size = 9 deg")
	assert_almost_eq(nb._storm_strengths[0], 0.55, 0.001, "GDS strength = 0.55")
	assert_eq(nb._storm_kinds[0], NeptuneBiome.STORM_DARK, "GDS is dark kind")


func test_neptune_companion_white_storm():
	var nb := NeptuneBiome.new()
	nb.seed_features(42)
	assert_almost_eq(nb._storm_lats[1], -0.2, 0.001, "companion lat = -0.2")
	assert_almost_eq(nb._storm_lons[1], 0.35, 0.001, "companion lon = 0.35")
	assert_almost_eq(nb._storm_sizes[1], deg_to_rad(3.5), 0.001, "companion size = 3.5 deg")
	assert_eq(nb._storm_kinds[1], NeptuneBiome.STORM_WHITE, "companion is white")


func test_neptune_gds_always_first():
	for seed_val in [1, 42, 123]:
		var nb := NeptuneBiome.new()
		nb.seed_features(seed_val)
		assert_true(nb._storm_lats.size() >= 2, "always has at least 2 storms")
		assert_almost_eq(nb._storm_lats[0], -0.3, 0.001, "GDS at slot 0 (seed %d)" % seed_val)
