extends OrbitalBody

var planet_name: String = "Jupiter"
var planet_color: Color = Color(0.85, 0.6, 0.3)
@export var trail_color0: Color = Color(0.85, 0.6, 0.3, 0.0)
@export var trail_color1: Color = Color(0.85, 0.6, 0.3, 0.4)
@export var collision_flash: float = 2.0
@export var collision_ring_color: Color = Color(0.85, 0.6, 0.3, 0.9)
@export var collision_ring_width: float = 6.0
@export var collision_ring_segments: int = 96
@export var collision_ring_timer: float = 2.5

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
