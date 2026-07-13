extends OrbitalBody

var planet_name: String = "Neptune"
var planet_color: Color = Color(0.2, 0.3, 0.85)
@export var trail_color0: Color = Color(0.2, 0.3, 0.85, 0.0)
@export var trail_color1: Color = Color(0.2, 0.3, 0.85, 0.4)
@export var collision_flash: float = 1.3
@export var collision_ring_color: Color = Color(0.2, 0.3, 0.85, 0.6)
@export var collision_ring_width: float = 3.0
@export var collision_ring_segments: int = 66
@export var collision_ring_timer: float = 1.7

func _get_planet_texture_size() -> int:
	return 54

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.6 + 0.4 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.2 * b, 0.3 * b, 0.85 * b, alpha)
