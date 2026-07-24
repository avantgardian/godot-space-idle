extends OrbitalBody

func _ready():
	biome = preload("res://resources/biomes/rocky_mercury.tres")
	planet_name = "Mercury"
	planet_color = Color(0.7, 0.7, 0.7, 1.0)
	collision_flash = 0.6
	collision_ring_color = Color(1, 0.9, 0.6, 0.5)
	collision_ring_width = 2.0
	collision_ring_segments = 48
	collision_ring_timer = 0.8
	use_shader = true
	super()
