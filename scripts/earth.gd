extends OrbitalBody

var planet_name: String = "Earth"
var planet_color: Color = Color(0.3, 0.6, 1.0, 1.0)
@export var collision_flash: float = 1.0
@export var collision_ring_color: Color = Color(0.3, 0.7, 1.0, 0.7)
@export var collision_ring_width: float = 3.5
@export var collision_ring_segments: int = 72
@export var collision_ring_timer: float = 1.5

func _ready():
	use_shader = true
	planet_type = &"terrestrial"
	planet_color = PAL.TERRA_OCEAN_DEEP
	# Earth surface spin ~6 deg/min visualized: rotation_rate drives the
	# shader's u_spin_rate; clouds drift ~3x faster via cloud_spin_rate.
	rotation_rate = 0.05
	sea_level = 0.5
	ocean_shelf_depth = 0.15
	polar_cap_lat_deg = 60.0
	polar_softness = 0.20
	cloud_coverage = 0.45
	cloud_spin_rate = 0.15
	cloud_scale = 3.0
	specular_power = 64.0
	city_lights = 0.0
	atm_color = PAL.ATM_RIM_EARTH
	super()

func _get_planet_texture_size() -> int:
	return 48

