extends OrbitalBody


func _ready():
	biome = preload("res://resources/biomes/rocky_mars.tres")
	planet_name = "Mars"
	planet_color = Color(0.85, 0.35, 0.15, 1.0)
	collision_flash = 0.7
	collision_ring_color = Color(0.9, 0.4, 0.15, 0.5)
	collision_ring_width = 2.0
	collision_ring_segments = 40
	collision_ring_timer = 0.9
	use_shader = true
	atm_color = PAL.ATM_RIM_MARS
	planet_seed = 639
	super()
