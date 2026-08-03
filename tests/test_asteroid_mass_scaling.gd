extends GutTest

const ASTEROID := preload("res://scripts/bodies/asteroid.gd")


func test_visual_radius_in_range():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	assert_between(a._visual_radius_px, 2.0, 10.0, "visual_radius_px in [2, 10]")


func test_spin_rate_in_range():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	assert_between(abs(a._spin_rate), 1.25, 2.5, "spin_rate in [1.25, 2.5]")


func test_visual_radius_monotonic_with_mass():
	const N := 50
	var largest_radius_at_min_mass := -1.0
	var smallest_radius_at_max_mass := 100.0
	for _i in range(N):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		a.spawn()

		if a.mass < (1.5e-8 + 6e-8) * 0.5:
			largest_radius_at_min_mass = max(largest_radius_at_min_mass, a._visual_radius_px)
		else:
			smallest_radius_at_max_mass = min(smallest_radius_at_max_mass, a._visual_radius_px)

	assert_lt(
		largest_radius_at_min_mass, smallest_radius_at_max_mass, "low-mass radii < high-mass radii"
	)


func test_collision_radius_coupled_to_visual_radius():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	assert_almost_eq(
		a.collision_radius,
		a._visual_radius_px * 0.7,
		0.001,
		"collision_radius = visual_radius * 0.7"
	)


func test_collision_radius_not_hardcoded():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	assert_ne(a.collision_radius, 6.0, "collision_radius not hardcoded 6.0")


func test_spin_rate_set_on_shader():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	var shader_spin: float = a._shader_mat.get_shader_parameter("u_spin_rate")
	assert_almost_eq(shader_spin, a._spin_rate, 0.001, "shader u_spin_rate matches _spin_rate")


func test_sprite_scale_from_mass():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	var expected_scale: float = a._visual_radius_px / (ASTEROID.TEXTURE_SIZE * 0.5)
	assert_almost_eq(
		a._sprite.scale.x,
		expected_scale,
		0.001,
		"sprite scale.x matches visual_radius / (TEXTURE_SIZE/2)"
	)
	assert_almost_eq(
		a._sprite.scale.y,
		expected_scale,
		0.001,
		"sprite scale.y matches visual_radius / (TEXTURE_SIZE/2)"
	)


func test_density_ratio_default():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	assert_eq(a._density_ratio, 1.0, "_density_ratio defaults to 1.0")


func test_sprite_rotation_stays_zero():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	a.spawn()
	a._process(1.0)
	assert_eq(a._sprite.rotation, 0.0, "sprite rotation stays zero (shader handles spin)")
