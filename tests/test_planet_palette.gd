extends GutTest

const PAL := preload("res://scripts/util/planet_palette.gd")

func _validate_color(c: Color, token_name: String):
	assert_gte(c.r, 0.0, token_name + " red >= 0")
	assert_gte(c.g, 0.0, token_name + " green >= 0")
	assert_gte(c.b, 0.0, token_name + " blue >= 0")
	assert_lte(c.r, 1.0, token_name + " red <= 1")
	assert_lte(c.g, 1.0, token_name + " green <= 1")
	assert_lte(c.b, 1.0, token_name + " blue <= 1")
	assert_between(c.a, 0.0, 1.0, token_name + " alpha in [0,1]")

func test_rocky_tokens_valid():
	_validate_color(PAL.ROCKY_MERCURY_HI, "ROCKY_MERCURY_HI")
	_validate_color(PAL.ROCKY_MERCURY_LO, "ROCKY_MERCURY_LO")
	_validate_color(PAL.ROCKY_MARS_HI, "ROCKY_MARS_HI")
	_validate_color(PAL.ROCKY_MARS_LO, "ROCKY_MARS_LO")
	_validate_color(PAL.ROCKY_MARS_ICE, "ROCKY_MARS_ICE")
	_validate_color(PAL.ROCKY_CRATER_SHADOW, "ROCKY_CRATER_SHADOW")
	_validate_color(PAL.ROCKY_ASTEROID_C_HI, "ROCKY_ASTEROID_C_HI")
	_validate_color(PAL.ROCKY_ASTEROID_C_LO, "ROCKY_ASTEROID_C_LO")
	_validate_color(PAL.ROCKY_ASTEROID_S_HI, "ROCKY_ASTEROID_S_HI")
	_validate_color(PAL.ROCKY_ASTEROID_S_LO, "ROCKY_ASTEROID_S_LO")
	_validate_color(PAL.ROCKY_ASTEROID_M_HI, "ROCKY_ASTEROID_M_HI")
	_validate_color(PAL.ROCKY_ASTEROID_M_LO, "ROCKY_ASTEROID_M_LO")
	_validate_color(PAL.ROCKY_ASTEROID_X_HI, "ROCKY_ASTEROID_X_HI")
	_validate_color(PAL.ROCKY_ASTEROID_X_LO, "ROCKY_ASTEROID_X_LO")

func test_greenhouse_tokens_valid():
	_validate_color(PAL.VENUS_CLOUD_HI, "VENUS_CLOUD_HI")
	_validate_color(PAL.VENUS_CLOUD_LO, "VENUS_CLOUD_LO")
	_validate_color(PAL.VENUS_SURFACE_LAVA, "VENUS_SURFACE_LAVA")

func test_terrestrial_tokens_valid():
	_validate_color(PAL.TERRA_OCEAN_DEEP, "TERRA_OCEAN_DEEP")
	_validate_color(PAL.TERRA_OCEAN_SHALLOW, "TERRA_OCEAN_SHALLOW")
	_validate_color(PAL.TERRA_LAND_TROPICAL, "TERRA_LAND_TROPICAL")
	_validate_color(PAL.TERRA_LAND_DESERT, "TERRA_LAND_DESERT")
	_validate_color(PAL.TERRA_LAND_TUNDRA, "TERRA_LAND_TUNDRA")
	_validate_color(PAL.TERRA_ICE_CAP, "TERRA_ICE_CAP")
	_validate_color(PAL.TERRA_CLOUD_WHITE, "TERRA_CLOUD_WHITE")
	_validate_color(PAL.TERRA_OCEAN_SPECULAR, "TERRA_OCEAN_SPECULAR")

func test_gas_giant_tokens_valid():
	_validate_color(PAL.GAS_BAND_TAN_HI, "GAS_BAND_TAN_HI")
	_validate_color(PAL.GAS_BAND_TAN_LO, "GAS_BAND_TAN_LO")
	_validate_color(PAL.GAS_STORM_RUST, "GAS_STORM_RUST")
	_validate_color(PAL.GAS_STORM_WHITE, "GAS_STORM_WHITE")
	_validate_color(PAL.SATURN_BAND_HI, "SATURN_BAND_HI")
	_validate_color(PAL.SATURN_BAND_LO, "SATURN_BAND_LO")

func test_ice_giant_tokens_valid():
	_validate_color(PAL.ICE_METHANE_BLUE, "ICE_METHANE_BLUE")
	_validate_color(PAL.ICE_DEEP_BLUE, "ICE_DEEP_BLUE")
	_validate_color(PAL.ICE_STORM_DARK, "ICE_STORM_DARK")
	_validate_color(PAL.ICE_HAZE_WHITE, "ICE_HAZE_WHITE")

func test_atmosphere_tokens_valid():
	_validate_color(PAL.ATM_RIM_EARTH, "ATM_RIM_EARTH")
	_validate_color(PAL.ATM_RIM_VENUS, "ATM_RIM_VENUS")
	_validate_color(PAL.ATM_RIM_MARS, "ATM_RIM_MARS")
	_validate_color(PAL.ATM_RIM_ICE, "ATM_RIM_ICE")

func test_ring_tokens_valid():
	_validate_color(PAL.RING_SATURN_TAN, "RING_SATURN_TAN")
	_validate_color(PAL.RING_SATURN_DARK, "RING_SATURN_DARK")
