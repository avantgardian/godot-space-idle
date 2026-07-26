extends GutTest

const ORBITAL_BODY := preload("res://scripts/bodies/orbital_body.gd")

func test_initial_gm_keplers_third_law():
	var body: Node2D = autofree(ORBITAL_BODY.new())
	add_child(body)
	body.orbit_radius = 500.0
	body.orbit_period = 48.0
	var expected: float = 4.0 * PI * PI * 500.0 * 500.0 * 500.0 / (48.0 * 48.0)
	assert_eq(body._initial_gm(), expected, "_initial_gm matches Kepler's third law")

func test_initial_gm_linear_in_radius_cubed():
	var body: Node2D = autofree(ORBITAL_BODY.new())
	add_child(body)
	body.orbit_radius = 1000.0
	body.orbit_period = 48.0
	var gm_large: float = body._initial_gm()
	body.orbit_radius = 500.0
	var gm_small: float = body._initial_gm()
	assert_gt(gm_large, gm_small, "GM grows with orbit radius")

func test_initial_gm_inverse_in_period_squared():
	var body: Node2D = autofree(ORBITAL_BODY.new())
	add_child(body)
	body.orbit_radius = 500.0
	body.orbit_period = 24.0
	var gm_fast: float = body._initial_gm()
	body.orbit_period = 48.0
	var gm_slow: float = body._initial_gm()
	assert_gt(gm_fast, gm_slow, "GM decreases with longer period")

func test_sun_collision_r_monotonic():
	assert_gt(ORBITAL_BODY.sun_collision_r(2.0), ORBITAL_BODY.sun_collision_r(1.0), "sun_collision_r grows with mass")
	assert_gt(ORBITAL_BODY.sun_collision_r(10.0), ORBITAL_BODY.sun_collision_r(5.0), "sun_collision_r grows with mass")

func test_sun_collision_r_plausible_bounds():
	var r_zero: float = ORBITAL_BODY.sun_collision_r(0.0)
	assert_gt(r_zero, 100.0, "Collision radius at mass=0 is above minimum plausible")
	assert_lt(r_zero, 120.0, "Collision radius at mass=0 is below maximum plausible")
	var r_one: float = ORBITAL_BODY.sun_collision_r(1.0)
	assert_gt(r_one, 100.0, "Collision radius at mass=1 is above minimum")
	assert_lt(r_one, 150.0, "Collision radius at mass=1 is reasonable")

func test_sun_collision_r_matches_formula():
	var mass: float = 4.0
	var expected: float = (128.0 + sqrt(mass) * 8.0) * 0.85
	assert_eq(ORBITAL_BODY.sun_collision_r(mass), expected, "sun_collision_r matches the formula")
