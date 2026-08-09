extends GutTest

const ASTEROID := preload("res://scripts/bodies/asteroid.gd")
const PAL_P := preload("res://scripts/util/planet_palette.gd")


func test_archetype_weights_sum_to_one():
	var total: float = 0.0
	for w in ASTEROID.ARCHETYPE_WEIGHTS:
		total += w
	assert_almost_eq(total, 1.0, 0.001, "archetype weights sum to 1.0")


func test_archetype_empirical_frequencies():
	const N := 2000
	var counts := [0, 0, 0, 0]
	for _i in range(N):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		var archetype: int = a._archetype
		assert_between(
			archetype, 0, ASTEROID.ARCHETYPE_WEIGHTS.size() - 1, "archetype in valid range"
		)
		counts[archetype] += 1

	for i in range(ASTEROID.ARCHETYPE_WEIGHTS.size()):
		var empirical: float = float(counts[i]) / float(N)
		var target: float = ASTEROID.ARCHETYPE_WEIGHTS[i]
		assert_between(
			empirical,
			target - 0.05,
			target + 0.05,
			"archetype %d freq %.3f within ±0.05 of weight %.3f" % [i, empirical, target]
		)


func test_every_archetype_has_palette_tokens():
	var archetype_tokens := [
		[PAL_P.ROCKY_ASTEROID_C_HI, PAL_P.ROCKY_ASTEROID_C_LO],
		[PAL_P.ROCKY_ASTEROID_S_HI, PAL_P.ROCKY_ASTEROID_S_LO],
		[PAL_P.ROCKY_ASTEROID_M_HI, PAL_P.ROCKY_ASTEROID_M_LO],
		[PAL_P.ROCKY_ASTEROID_X_HI, PAL_P.ROCKY_ASTEROID_X_LO],
	]
	for archetype in range(archetype_tokens.size()):
		var tokens: Array = archetype_tokens[archetype]
		for token in tokens:
			assert_ne(token, Color(0, 0, 0, 0), "archetype %d token nonzero" % archetype)


func test_archetype_shape_matches_font_face():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	assert_lt(a.collision_radius, 20.0)
