extends OrbitalBody

func _ready():
	planet_name = "Mars"
	planet_color = Color(0.85, 0.35, 0.15, 1.0)
	collision_flash = 0.7
	collision_ring_color = Color(0.9, 0.4, 0.15, 0.5)
	collision_ring_width = 2.0
	collision_ring_segments = 40
	collision_ring_timer = 0.9
	use_shader = true
	planet_type = &"rocky"
	crater_count = 6
	polar_cap_lat_deg = 60.0
	polar_softness = 0.20
	atm_color = PAL.ATM_RIM_MARS
	super()

func _get_planet_texture_size() -> int:
	return 26

func _get_rocky_hi() -> Color:
	return PAL.ROCKY_MARS_HI

func _get_rocky_lo() -> Color:
	return PAL.ROCKY_MARS_LO