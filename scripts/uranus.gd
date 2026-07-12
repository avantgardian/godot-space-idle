extends OrbitalBody

var planet_name: String = "Uranus"
var planet_color: Color = Color(0.4, 0.7, 0.9)
var planet_speed: float = 6.8

func _ready():
	orbit_radius = 2200.0
	orbit_period = 1074.0
	start_angle = 1.5
	mass = 4.35e-5
	collision_radius = 28.0
	super()
	trail_max = 32220 # full orbit: 1074s × 30 pts/s

func _get_planet_texture_size() -> int:
	return 56

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.5 * b, 0.8 * b, 0.9 * b, alpha)
