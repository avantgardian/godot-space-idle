extends GutTest

const SUN := preload("res://scripts/bodies/sun.gd")


func test_generate_stores_default_params():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({})
	assert_not_null(s._shader_mat, "shader material created")
	assert_almost_eq(s._limb_strength, 0.65, 0.01, "default limb_strength")


func test_generate_applies_star_params():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	(
		s
		. generate(
			{
				core_0 = Color(0.1, 0.2, 0.3),
				core_1 = Color(0.4, 0.5, 0.6),
				core_2 = Color(0.7, 0.8, 0.9),
				glow_tint = Color(1.0, 1.0, 1.0),
				base_mod = Color(1.0, 0.0, 0.0),
				hot_mod = Color(0.0, 1.0, 0.0),
				start_mass = 2.0,
				mass_span = 3.0,
				limb_strength = 0.42,
				granulation_scale = 2.5,
				corona_falloff = 1.8,
				corona_radius_mult = 2.0,
			}
		)
	)
	assert_eq(s._star_core_0, Color(0.1, 0.2, 0.3), "core_0 stored")
	assert_eq(s._star_core_1, Color(0.4, 0.5, 0.6), "core_1 stored")
	assert_eq(s._star_core_2, Color(0.7, 0.8, 0.9), "core_2 stored")
	assert_almost_eq(s._limb_strength, 0.42, 0.01, "limb_strength stored")
	assert_almost_eq(s._granulation_scale, 2.5, 0.01, "granulation_scale stored")
	assert_almost_eq(s._corona_falloff, 1.8, 0.01, "corona_falloff stored")
	assert_almost_eq(s._corona_radius_mult, 2.0, 0.01, "corona_radius_mult stored")
	assert_almost_eq(s._star_start_mass, 2.0, 0.01, "start_mass stored")
	assert_almost_eq(s._star_mass_span, 3.0, 0.01, "mass_span stored")


func test_shader_uniforms_set_by_generate():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({})
	var limber: Variant = s._shader_mat.get_shader_parameter("u_limb_strength")
	assert_not_null(limber, "u_limb_strength set")
	var gran: Variant = s._shader_mat.get_shader_parameter("u_granulation_scale")
	assert_not_null(gran, "u_granulation_scale set")
	var core0: Variant = s._shader_mat.get_shader_parameter("u_core_0")
	assert_not_null(core0, "u_core_0 set")


func test_generate_creates_glow_sprites():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({texture_size = 128})
	assert_not_null(s._glow_outer, "outer glow created")
	assert_not_null(s._glow_inner, "inner glow created")


func test_flash_accumulates_intensity():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.flash(0.5)
	assert_almost_eq(s._collision_flash, 0.5, 0.001, "flash set to 0.5")
	s.flash(0.8)
	assert_almost_eq(s._collision_flash, 0.8, 0.001, "flash accumulates to max")
	s.flash(0.3)
	assert_almost_eq(s._collision_flash, 0.8, 0.001, "smaller flash doesn't reduce")


func test_set_animations_enabled():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.set_animations_enabled(false)
	assert_false(s._animations_enabled, "animations disabled")
	s.set_animations_enabled(true)
	assert_true(s._animations_enabled, "animations re-enabled")


func test_process_animations_disabled_resets_scale():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({texture_size = 128})
	s.set_animations_enabled(false)
	s._process(0.1)
	assert_eq(s.scale, Vector2.ONE, "scale reset to base when animations disabled")
	assert_eq(s.modulate, Color.WHITE, "modulate reset to white")


func test_process_collision_flash_decays():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({texture_size = 128})
	s.set_animations_enabled(false)
	s.flash(0.6)
	var before: float = s._collision_flash
	s._process(0.1)
	assert_lt(s._collision_flash, before, "collision flash decays over time")


func test_process_increments_sun_time():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({texture_size = 128})
	var before: float = s.sun_time
	s._process(0.1)
	assert_gt(s.sun_time, before, "sun_time increments")


func test_generate_partial_params_keep_defaults():
	var s: Sprite2D = autofree(SUN.new())
	add_child(s)
	s.generate({limb_strength = 0.25})
	assert_almost_eq(s._limb_strength, 0.25, 0.01, "limb_strength updated")
	assert_almost_eq(s._granulation_scale, 1.0, 0.01, "granulation_scale default preserved")
