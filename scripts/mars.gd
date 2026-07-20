extends OrbitalBody

var planet_name: String = "Mars"
var planet_color: Color = Color(0.85, 0.35, 0.15, 1.0)
@export var collision_flash: float = 0.7
@export var collision_ring_color: Color = Color(0.9, 0.4, 0.15, 0.5)
@export var collision_ring_width: float = 2.0
@export var collision_ring_segments: int = 40
@export var collision_ring_timer: float = 0.9

func _ready():
	use_shader = true
	planet_type = &"rocky"
	crater_count = 6
	polar_cap_lat_deg = 60.0
	polar_softness = 0.20
	atm_color = PAL.ATM_RIM_MARS
	super()

func _get_planet_texture_size() -> int:
	return 26

func _get_rocky_hi() -> Color:
	return PAL.ROCKY_MARS_HI

func _get_rocky_lo() -> Color:
	return PAL.ROCKY_MARS_LO