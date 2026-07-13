extends OrbitalBody

var planet_name: String = "Mars"
var planet_color: Color = Color(0.85, 0.35, 0.15)

func _get_planet_texture_size() -> int:
	return 26

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.75 * b, 0.35 * b, 0.15 * b, alpha)
