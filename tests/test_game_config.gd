extends GutTest

const GC := preload("res://scripts/util/game_config.gd")

func test_click_mass_gain():
	assert_eq(GC.CLICK_MASS_GAIN, 0.1, "CLICK_MASS_GAIN == 0.1")
