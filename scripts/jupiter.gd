extends OrbitalBody

var planet_name: String = "Jupiter"
var planet_color: Color = Color(0.85, 0.6, 0.3)
var planet_speed: float = 13.1

func _ready():
	orbit_radius = 1400.0
	orbit_period = 355.0
	start_angle = 0.5
	mass = 9.54e-4
	collision_radius = 50.0
	_trail_max = 10650 # full orbit: 355s × 30 pts/s
	super()

func _get_planet_texture_size() -> int:
	return 100

func _get_planet_color(t: float, _x: int, y: int) -> Color:
	var band: float = sin(float(y) * 0.7) * 0.15
	var b: float = 0.65 + 0.35 * (1.0 - t) + band
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(
		clampf((0.85 + band * 0.3) * b, 0, 1),
		clampf((0.65 + band * 0.2) * b, 0, 1),
		clampf((0.3 - band * 0.1) * b, 0, 1),
		alpha
	)
