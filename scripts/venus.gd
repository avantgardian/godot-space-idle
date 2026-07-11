extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 500.0
	orbit_period = 48.0
	start_angle = 2.5
	mass = 0.815
	collision_radius = 22.0
	_trail_max = 1200
	_generate_texture()
	_reset()

func _get_planet_texture_size() -> int:
	return 44

func _get_planet_color(t: float, x: int, y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.8:
		alpha = 1.0 - (t - 0.8) / 0.2
	return Color(0.85 * b, 0.75 * b, 0.5 * b, alpha)
