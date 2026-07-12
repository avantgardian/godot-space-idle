extends OrbitalBody

var planet_name: String = "Mercury"
var planet_color: Color = Color(0.7, 0.7, 0.7)
var planet_speed: float = 47.4

func _ready():
	super()

func _get_planet_texture_size() -> int:
	return 36

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.5 + 0.5 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.7 * b, 0.7 * b, 0.72 * b, alpha)

