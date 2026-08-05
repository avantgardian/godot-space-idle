extends OrbitalBody


func _ready():
	biome = preload("res://resources/biomes/greenhouse_venus.tres")
	planet_name = "Venus"
	planet_color = Color(0.95, 0.85, 0.5, 1.0)
	collision_flash = 0.8
	collision_ring_color = Color(1, 0.8, 0.4, 0.6)
	collision_ring_width = 3.0
	collision_ring_segments = 64
	collision_ring_timer = 1.2
	use_shader = true
	rotation_rate = 0.08
	atm_color = PAL.ATM_RIM_VENUS
	planet_seed = 315
	super()
