extends OrbitalBody

var planet_name: String = "Uranus"
var planet_color: Color = Color(0.4, 0.7, 0.9)
@export var collision_flash: float = 1.2
@export var collision_ring_color: Color = Color(0.4, 0.7, 0.9, 0.6)
@export var collision_ring_width: float = 3.0
@export var collision_ring_segments: int = 64
@export var collision_ring_timer: float = 1.6

func _get_planet_texture_size() -> int:
	return 56

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.5 * b, 0.8 * b, 0.9 * b, alpha)
