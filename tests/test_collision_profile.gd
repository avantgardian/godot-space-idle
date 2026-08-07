extends GutTest

const COLLISION_PROFILE := preload("res://scripts/util/collision_profile.gd")
const ORBITAL_BODY := preload("res://scripts/bodies/orbital_body.gd")
const MERCURY_PROFILE := preload("res://resources/collision/mercury.tres")
const ASTEROID_PROFILE := preload("res://resources/collision/asteroid.tres")


func test_collision_profile_defaults():
	var profile = autofree(COLLISION_PROFILE.new())
	assert_eq(profile.flash, 0.5, "default flash")
	assert_eq(profile.ring_width, 2.0, "default ring_width")
	assert_eq(profile.ring_segments, 48, "default ring_segments")
	assert_eq(profile.ring_timer, 1.0, "default ring_timer")


func test_mercury_profile_loaded():
	assert_not_null(MERCURY_PROFILE, "mercury profile loads")
	assert_eq(MERCURY_PROFILE.flash, 0.6, "mercury flash")
	assert_eq(MERCURY_PROFILE.ring_width, 2.0, "mercury ring_width")
	assert_eq(MERCURY_PROFILE.ring_segments, 48, "mercury ring_segments")
	assert_eq(MERCURY_PROFILE.ring_timer, 0.8, "mercury ring_timer")


func test_asteroid_profile_loaded():
	assert_not_null(ASTEROID_PROFILE, "asteroid profile loads")
	assert_eq(ASTEROID_PROFILE.flash, 0.2, "asteroid flash")
	assert_eq(ASTEROID_PROFILE.ring_width, 1.5, "asteroid ring_width")
	assert_eq(ASTEROID_PROFILE.ring_segments, 24, "asteroid ring_segments")
	assert_eq(ASTEROID_PROFILE.ring_timer, 0.4, "asteroid ring_timer")


func test_orbital_body_has_collision_profile_export():
	var body: Node2D = autofree(ORBITAL_BODY.new())
	add_child(body)
	var profile = autofree(COLLISION_PROFILE.new())
	profile.flash = 0.9
	body.collision_profile = profile
	assert_eq(body.collision_profile.flash, 0.9, "collision_profile is assignable")


func test_collision_profile_all_planets_have_profile():
	var files := [
		"res://resources/collision/mercury.tres",
		"res://resources/collision/venus.tres",
		"res://resources/collision/earth.tres",
		"res://resources/collision/mars.tres",
		"res://resources/collision/jupiter.tres",
		"res://resources/collision/saturn.tres",
		"res://resources/collision/uranus.tres",
		"res://resources/collision/neptune.tres",
		"res://resources/collision/asteroid.tres",
	]
	for f in files:
		var profile = load(f)
		assert_not_null(profile, "%s loads" % f)
		assert_gt(profile.flash, 0.0, "%s flash > 0" % f)
		assert_gt(profile.ring_width, 0.0, "%s ring_width > 0" % f)
		assert_gt(profile.ring_segments, 2, "%s ring_segments > 2" % f)
		assert_gt(profile.ring_timer, 0.0, "%s ring_timer > 0" % f)
