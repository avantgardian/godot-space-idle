extends OrbitalBody

var planet_name: String = "Mercury"
var planet_color: Color = Color(0.7, 0.7, 0.7, 1.0)
@export var collision_flash: float = 0.6
@export var collision_ring_color: Color = Color(1, 0.9, 0.6, 0.5)
@export var collision_ring_width: float = 2.0
@export var collision_ring_segments: int = 48
@export var collision_ring_timer: float = 0.8

func _ready():
	use_shader = true
	planet_type = &"rocky"
	crater_count = 12
	polar_cap_lat_deg = 0.0
	super()

func _get_planet_texture_size() -> int:
	return 36

func _get_rocky_hi() -> Color:
	return PAL.ROCKY_MERCURY_HI

func _get_rocky_lo() -> Color:
	return PAL.ROCKY_MERCURY_LO
