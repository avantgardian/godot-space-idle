extends OrbitalBody

func _ready():
	planet_name = "Uranus"
	planet_color = Color(0.4, 0.7, 0.9)
	collision_flash = 1.2
	collision_ring_color = Color(0.4, 0.7, 0.9, 0.6)
	collision_ring_width = 3.0
	collision_ring_segments = 64
	collision_ring_timer = 1.6
	use_shader = true
	planet_type = &"ice_giant"
	planet_color = PAL.ICE_METHANE_BLUE
	ice_variant = 0
	axial_tilt_deg = 98.0
	rotation_rate = 0.15
	band_count = 6
	band_sharp = 0.05
	shear_amp = 0.02
	ice_band_contrast = 0.03
	storm_count = 0
	ice_haze_strength = 0.0
	atm_color = PAL.ATM_RIM_ICE
	super()

func _get_planet_texture_size() -> int:
	return 56

func _get_ice_base_color() -> Color:
	return PAL.ICE_METHANE_BLUE

func _get_ice_haze_color() -> Color:
	return PAL.ICE_HAZE_WHITE

func _get_ice_storm_dark() -> Color:
	return PAL.ICE_STORM_DARK
