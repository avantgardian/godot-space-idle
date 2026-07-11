extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 2200.0
	orbit_period = 364.0
	start_angle = 1.5
	mass = 14.5
	collision_radius = 28.0
	_trail_max = 3500
	_generate_texture()
	_reset()

func _get_planet_texture_size() -> int:
	return 56

func _get_planet_color(t: float, x: int, y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.5 * b, 0.8 * b, 0.9 * b, alpha)
