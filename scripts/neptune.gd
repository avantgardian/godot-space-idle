extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 2600.0
	orbit_period = 468.0
	start_angle = 4.5
	mass = 17.1
	collision_radius = 27.0
	_trail_max = 4000
	_generate_texture()
	_reset()

func _get_planet_texture_size() -> int:
	return 54

func _get_planet_color(t: float, x: int, y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.2 * b, 0.3 * b, 0.85 * b, alpha)
