extends OrbitalBody


func _ready():
	biome = preload("res://resources/biomes/gas_giant_jupiter.tres")
	planet_name = "Jupiter"
	planet_color = PAL.GAS_BAND_TAN_HI
	collision_flash = 2.0
	collision_ring_color = Color(0.85, 0.6, 0.3, 0.9)
	collision_ring_width = 6.0
	collision_ring_segments = 96
	collision_ring_timer = 2.5
	use_shader = true
	rotation_rate = 0.4
	planet_seed = 381
	super()
