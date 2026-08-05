extends OrbitalBody


func _ready():
	biome = preload("res://resources/biomes/terrestrial_earth.tres")
	planet_name = "Earth"
	planet_color = PAL.TERRA_OCEAN_DEEP
	collision_flash = 1.0
	collision_ring_color = Color(0.3, 0.7, 1.0, 0.7)
	collision_ring_width = 3.5
	collision_ring_segments = 72
	collision_ring_timer = 1.5
	use_shader = true
	rotation_rate = 0.05
	atm_color = PAL.ATM_RIM_EARTH
	planet_seed = 634
	super()
