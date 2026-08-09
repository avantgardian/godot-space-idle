extends GutTest

const DU := preload("res://scripts/util/draw_utils.gd")
const PAL := preload("res://scripts/util/tron_palette.gd")


func test_neon_widths_are_positive():
	assert_gt(DU.NEON_GLOW_WIDTH, 0.0, "glow width > 0")
	assert_gt(DU.NEON_LINE_WIDTH, 0.0, "line width > 0")
	assert_gt(DU.NEON_BRIGHT_WIDTH, 0.0, "bright width > 0")


func test_neon_widths_ordered_glow_gt_line_gt_bright():
	assert_gt(DU.NEON_GLOW_WIDTH, DU.NEON_LINE_WIDTH, "glow wider than line")
	assert_gt(DU.NEON_LINE_WIDTH, DU.NEON_BRIGHT_WIDTH, "line wider than bright")


func test_accent_widths_positive():
	assert_gt(DU.ACCENT_GLOW_WIDTH, 0.0, "accent glow > 0")
	assert_gt(DU.ACCENT_LINE_WIDTH, 0.0, "accent line > 0")


func test_pulsate_factor_at_phase_0_returns_mid():
	var min_val := 0.35
	var expected_mid: float = min_val + (1.0 - min_val) * 0.5
	assert_almost_eq(DU.pulsate_factor(0.0, min_val), expected_mid, 0.001, "phase 0 = mid")


func test_pulsate_factor_at_pi_half_returns_1():
	assert_almost_eq(DU.pulsate_factor(PI / 2.0, 0.35), 1.0, 0.001, "phase PI/2 = 1.0")


func test_pulsate_factor_at_pi_returns_mid():
	assert_almost_eq(DU.pulsate_factor(PI, 0.35), 0.675, 0.001, "phase PI = mid")


func test_pulsate_factor_at_3pi_half_returns_min():
	assert_almost_eq(DU.pulsate_factor(3.0 * PI / 2.0, 0.35), 0.35, 0.001, "phase 3PI/2 = min")


func test_pulsate_factor_bounded_by_min_and_1():
	for phase in range(0, 100):
		var f := phase * 0.1
		var v := DU.pulsate_factor(f, 0.35)
		assert_between(v, 0.35, 1.0, "in [min, 1] at phase %f" % f)


func test_pulsate_factor_uses_custom_min():
	for phase in range(0, 10):
		var f := phase * 0.5
		var v := DU.pulsate_factor(f, 0.1)
		assert_between(v, 0.1, 1.0, ">= custom min 0.1")


func test_modulate_alpha_scales_alpha():
	var c := Color(1.0, 0.5, 0.25, 0.8)
	var result := DU.modulate_alpha(c, 0.5)
	assert_almost_eq(result.r, 1.0, 0.001, "r untouched")
	assert_almost_eq(result.g, 0.5, 0.001, "g untouched")
	assert_almost_eq(result.b, 0.25, 0.001, "b untouched")
	assert_almost_eq(result.a, 0.4, 0.001, "alpha = 0.8 * 0.5")


func test_modulate_alpha_factor_zero():
	var c := Color.WHITE
	var result := DU.modulate_alpha(c, 0.0)
	assert_eq(result.a, 0.0, "alpha zero when factor=0")


func test_modulate_alpha_factor_one():
	var c := Color(1.0, 2.0, 3.0, 0.7)
	var result := DU.modulate_alpha(c, 1.0)
	assert_almost_eq(result.a, 0.7, 0.001, "alpha unchanged when factor=1")


func test_trail_head_alpha_matches_constant():
	var result := DU.trail_head(Color.RED)
	assert_almost_eq(result.a, DU.TRAIL_HEAD_ALPHA, 0.001, "head alpha matches constant")


func test_trail_tail_alpha_matches_constant():
	var result := DU.trail_tail(Color.RED)
	assert_almost_eq(result.a, DU.TRAIL_TAIL_ALPHA, 0.001, "tail alpha matches constant")


func test_trail_head_is_tint_of_planet_color():
	var planet := Color(0.1, 0.0, 0.8)
	var result := DU.trail_head(planet)
	var expected_r := lerpf(PAL.HULL_BRIGHT.r, planet.r, DU.TRAIL_HEAD_TINT)
	var expected_b := lerpf(PAL.HULL_BRIGHT.b, planet.b, DU.TRAIL_HEAD_TINT)
	assert_almost_eq(result.r, expected_r, 0.01, "red channel tinted")
	assert_almost_eq(result.b, expected_b, 0.01, "blue channel tinted")


func test_trail_tail_is_tint_of_planet_color():
	var planet := Color(0.1, 0.0, 0.8)
	var result := DU.trail_tail(planet)
	var expected_r := lerpf(PAL.HULL_LINE.r, planet.r, DU.TRAIL_TAIL_TINT)
	assert_almost_eq(result.r, expected_r, 0.01, "red channel tinted")


func test_trail_head_white_is_tinted():
	var white := Color(1.0, 1.0, 1.0)
	var result := DU.trail_head(white)
	var expected: float = lerpf(PAL.HULL_BRIGHT.r, 1.0, DU.TRAIL_HEAD_TINT)
	assert_almost_eq(result.r, expected, 0.01, "white planet = lerped HULL_BRIGHT")


func test_trail_tail_black_is_tinted():
	var black := Color(0.0, 0.0, 0.0)
	var result := DU.trail_tail(black)
	var expected: float = lerpf(PAL.HULL_LINE.r, 0.0, DU.TRAIL_TAIL_TINT)
	assert_almost_eq(result.r, expected, 0.01, "black planet = lerped HULL_LINE")
