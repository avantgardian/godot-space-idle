extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 950.0
	orbit_period = 123.0
	start_angle = 4.0
	mass = 3.21e-7
	collision_radius = 13.0
	_trail_max = 1845  # half orbit: 123s × 30 pts/s ÷ 2
	_generate_texture()
	_reset()

func _get_planet_texture_size() -> int:
	return 26

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.75 * b, 0.35 * b, 0.15 * b, alpha)
