extends OrbitalBody

var planet_name: String = "Mars"
var planet_color: Color = Color(0.85, 0.35, 0.15)
@export var collision_flash: float = 0.7
@export var collision_ring_color: Color = Color(0.9, 0.4, 0.15, 0.5)
@export var collision_ring_width: float = 2.0
@export var collision_ring_segments: int = 40
@export var collision_ring_timer: float = 0.9

func _get_planet_texture_size() -> int:
	return 26

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.75 * b, 0.35 * b, 0.15 * b, alpha)
