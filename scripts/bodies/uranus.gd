extends OrbitalBody

func _ready():
	biome = preload("res://resources/biomes/ice_giant_uranus.tres")
	planet_name = "Uranus"
	planet_color = PAL.ICE_METHANE_BLUE
	collision_flash = 1.2
	collision_ring_color = Color(0.4, 0.7, 0.9, 0.6)
	collision_ring_width = 3.0
	collision_ring_segments = 64
	collision_ring_timer = 1.6
	use_shader = true
	axial_tilt_deg = 98.0
	rotation_rate = 0.15
	atm_color = PAL.ATM_RIM_ICE
	super()
