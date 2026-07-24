extends OrbitalBody

func _ready():
	biome = preload("res://resources/biomes/ice_giant_neptune.tres")
	planet_name = "Neptune"
	planet_color = PAL.ICE_DEEP_BLUE
	collision_flash = 1.3
	collision_ring_color = Color(0.2, 0.3, 0.85, 0.6)
	collision_ring_width = 3.0
	collision_ring_segments = 66
	collision_ring_timer = 1.7
	use_shader = true
	axial_tilt_deg = 28.32
	rotation_rate = 0.15
	atm_color = PAL.ATM_RIM_ICE
	super()
