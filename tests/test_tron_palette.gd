extends GutTest

const PAL := preload("res://scripts/util/tron_palette.gd")

func test_hull_line_alpha_is_one():
	assert_eq(PAL.HULL_LINE.a, 1.0, "HULL_LINE alpha == 1.0")

func test_hull_bright_alpha_is_one():
	assert_eq(PAL.HULL_BRIGHT.a, 1.0, "HULL_BRIGHT alpha == 1.0")

func test_ring_alpha_max_is_half():
	assert_eq(PAL.RING_ALPHA_MAX, 0.5, "RING_ALPHA_MAX == 0.5")

func test_ring_glow_alpha_capped():
	assert_lte(PAL.RING_GLOW.a, PAL.RING_ALPHA_MAX, "RING_GLOW alpha <= RING_ALPHA_MAX")

func test_ring_line_alpha_capped():
	assert_lte(PAL.RING_LINE.a, PAL.RING_ALPHA_MAX, "RING_LINE alpha <= RING_ALPHA_MAX")

func test_ring_bright_alpha_capped():
	assert_lte(PAL.RING_BRIGHT.a, PAL.RING_ALPHA_MAX, "RING_BRIGHT alpha <= RING_ALPHA_MAX")

func test_ring_pulse_min():
	assert_eq(PAL.RING_PULSE_MIN, 0.35, "RING_PULSE_MIN == 0.35")

func test_ring_pulse_speed():
	assert_eq(PAL.RING_PULSE_SPEED, 2.5, "RING_PULSE_SPEED == 2.5")

func test_bg_color_valid():
	var c: Color = PAL.BG
	assert_gte(c.r, 0.0, "BG red >= 0")
	assert_gte(c.g, 0.0, "BG green >= 0")
	assert_gte(c.b, 0.0, "BG blue >= 0")

func test_hull_glow_valid():
	var c: Color = PAL.HULL_GLOW
	assert_gte(c.r, 0.0, "HULL_GLOW red >= 0")
	assert_lte(c.r, 1.0, "HULL_GLOW red <= 1")

func test_accent_valid():
	var c: Color = PAL.ACCENT
	assert_gte(c.r, 0.0, "ACCENT red >= 0")
	assert_lte(c.a, 1.0, "ACCENT alpha <= 1")

func test_engine_port_valid():
	var c: Color = PAL.ENGINE_PORT
	assert_gte(c.g, 0.0, "ENGINE_PORT green >= 0")

func test_cockpit_valid():
	var c: Color = PAL.COCKPIT
	assert_gte(c.r, 0.0, "COCKPIT red >= 0")

func test_flame_outer_valid():
	var c: Color = PAL.FLAME_OUTER
	assert_between(c.a, 0.0, 1.0, "FLAME_OUTER alpha in [0,1]")

func test_all_alpha_in_range():
	var tokens: Array[Color] = [
		PAL.HULL_GLOW, PAL.HULL_LINE, PAL.HULL_BRIGHT,
		PAL.ACCENT, PAL.ACCENT_GLOW, PAL.COCKPIT, PAL.COCKPIT_GLOW,
		PAL.ENGINE_PORT, PAL.PORT_CORE, PAL.FLAME_OUTER, PAL.FLAME_INNER,
		PAL.RING_GLOW, PAL.RING_LINE, PAL.RING_BRIGHT,
	]
	var names: Array[String] = [
		"HULL_GLOW", "HULL_LINE", "HULL_BRIGHT",
		"ACCENT", "ACCENT_GLOW", "COCKPIT", "COCKPIT_GLOW",
		"ENGINE_PORT", "PORT_CORE", "FLAME_OUTER", "FLAME_INNER",
		"RING_GLOW", "RING_LINE", "RING_BRIGHT",
	]
	for i in range(tokens.size()):
		var c: Color = tokens[i]
		assert_between(c.a, 0.0, 1.0, names[i] + " alpha in [0,1]")
