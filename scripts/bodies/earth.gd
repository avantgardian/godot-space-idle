extends OrbitalBody

func _ready():
	planet_name = "Earth"
	planet_color = Color(0.3, 0.6, 1.0, 1.0)
	collision_flash = 1.0
	collision_ring_color = Color(0.3, 0.7, 1.0, 0.7)
	collision_ring_width = 3.5
	collision_ring_segments = 72
	collision_ring_timer = 1.5
	use_shader = true
	planet_type = &"terrestrial"
	planet_color = PAL.TERRA_OCEAN_DEEP
	# Earth surface spin ~6 deg/min visualized: rotation_rate drives the
	# shader's u_spin_rate; clouds drift ~3x faster via cloud_spin_rate.
	rotation_rate = 0.05
	sea_level = 0.5
	ocean_shelf_depth = 0.15
	polar_cap_lat_deg = 60.0
	polar_softness = 0.20
	cloud_coverage = 0.45
	cloud_spin_rate = 0.15
	cloud_scale = 3.0
	specular_power = 64.0
	city_lights = 0.0
	atm_color = PAL.ATM_RIM_EARTH
	super()

func _get_planet_texture_size() -> int:
	return 48

