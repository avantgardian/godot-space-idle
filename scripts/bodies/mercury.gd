extends OrbitalBody

func _ready():
	planet_name = "Mercury"
	planet_color = Color(0.7, 0.7, 0.7, 1.0)
	collision_flash = 0.6
	collision_ring_color = Color(1, 0.9, 0.6, 0.5)
	collision_ring_width = 2.0
	collision_ring_segments = 48
	collision_ring_timer = 0.8
	use_shader = true
	planet_type = &"rocky"
	crater_count = 12
	polar_cap_lat_deg = 0.0
	super()

func _get_planet_texture_size() -> int:
	return 36

func _get_rocky_hi() -> Color:
	return PAL.ROCKY_MERCURY_HI

func _get_rocky_lo() -> Color:
	return PAL.ROCKY_MERCURY_LO
