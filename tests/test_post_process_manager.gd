extends GutTest

const PPM := preload("res://scripts/components/post_process_manager.gd")


func test_trigger_increments_ca_impact():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_screen_shake_enabled(false)
	ppm.trigger()
	assert_gt(ppm._ca_impact, 0.0, "ca_impact > 0 after trigger")


func test_trigger_clamps_ca_impact():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_screen_shake_enabled(false)
	for _i in range(100):
		ppm.trigger()
	assert_true(ppm._ca_impact <= 0.015, "ca_impact clamped at 0.015")


func test_trigger_multiple_increments():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_screen_shake_enabled(false)
	ppm.trigger()
	var after1: float = ppm._ca_impact
	ppm.trigger()
	assert_gt(ppm._ca_impact, after1, "ca_impact increments again")


func test_process_decays_ca_impact():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_screen_shake_enabled(false)
	ppm.trigger()
	ppm.trigger()
	ppm.trigger()
	var before: float = ppm._ca_impact
	ppm._process(0.5)
	assert_lt(ppm._ca_impact, before, "ca_impact decays")


func test_process_floor_ca_at_zero():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm._ca_impact = 0.001
	ppm._process(1.0)
	assert_true(ppm._ca_impact >= 0.0, "ca_impact floors at 0")


func test_set_bloom_intensity_clamped():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_bloom_intensity(5.0)
	assert_eq(ppm._bloom_intensity, 2.0, "bloom clamped at 2.0")
	ppm.set_bloom_intensity(-1.0)
	assert_eq(ppm._bloom_intensity, 0.0, "bloom clamped at 0.0")


func test_set_bloom_intensity_in_range():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_bloom_intensity(1.5)
	assert_eq(ppm._bloom_intensity, 1.5, "bloom set to 1.5")


func test_get_bloom_intensity_returns_value():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_bloom_intensity(1.3)
	assert_eq(ppm.get_bloom_intensity(), 1.3, "getter returns stored value")


func test_set_screen_shake_enabled():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_screen_shake_enabled(false)
	assert_false(ppm._screen_shake_enabled, "screen shake disabled")
	ppm.set_screen_shake_enabled(true)
	assert_true(ppm._screen_shake_enabled, "screen shake enabled")


func test_colorblind_mode_default():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	assert_eq(ppm._colorblind_mode, 0, "default colorblind mode 0")


func test_set_colorblind_mode_toggles_visibility():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_colorblind_mode(1)
	assert_eq(ppm._colorblind_mode, 1, "mode set")
	assert_true(ppm._cb_rect.visible, "overlay visible at mode 1")

	ppm.set_colorblind_mode(0)
	assert_false(ppm._cb_rect.visible, "overlay hidden at mode 0")


func test_set_colorblind_mode_sets_shader():
	var ppm: Node = autofree(PPM.new())
	add_child(ppm)
	ppm.set_colorblind_mode(2)
	var mode: Variant = ppm._cb_mat.get_shader_parameter("u_mode")
	assert_not_null(mode, "shader u_mode set")
