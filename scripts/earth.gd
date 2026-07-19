extends OrbitalBody

var planet_name: String = "Earth"
var planet_color: Color = Color(0.3, 0.6, 1.0)
@export var collision_flash: float = 1.0
@export var collision_ring_color: Color = Color(0.3, 0.7, 1.0, 0.7)
@export var collision_ring_width: float = 3.5
@export var collision_ring_segments: int = 72
@export var collision_ring_timer: float = 1.5

func _get_planet_texture_size() -> int:
	return 48

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.7 + 0.3 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	if t < 0.3:
		return Color(0.3 * b, 0.6 * b, 0.4 * b, alpha)
	elif t < 0.6:
		return Color(0.4 * b, 0.7 * b, 0.5 * b, alpha)
	else:
		return Color(0.6 * b, 0.8 * b, 0.9 * b, alpha)
