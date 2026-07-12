extends OrbitalBody

func _ready():
	orbit_radius = 500.0
	orbit_period = 47.0
	start_angle = 2.5
	mass = 2.45e-6
	collision_radius = 22.0
	_trail_max = 1410  # full orbit: 47s × 30 pts/s
	super()

func _get_planet_texture_size() -> int:
	return 44

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.8:
		alpha = 1.0 - (t - 0.8) / 0.2
	return Color(0.85 * b, 0.75 * b, 0.5 * b, alpha)
