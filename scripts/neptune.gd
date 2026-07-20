extends OrbitalBody

var planet_name: String = "Neptune"
var planet_color: Color = Color(0.2, 0.3, 0.85)
@export var collision_flash: float = 1.3
@export var collision_ring_color: Color = Color(0.2, 0.3, 0.85, 0.6)
@export var collision_ring_width: float = 3.0
@export var collision_ring_segments: int = 66
@export var collision_ring_timer: float = 1.7

func _ready():
	use_shader = true
	planet_type = &"ice_giant"
	planet_color = PAL.ICE_DEEP_BLUE
	ice_variant = 1
	axial_tilt_deg = 28.32
	rotation_rate = 0.15
	band_count = 6
	band_sharp = 0.05
	shear_amp = 0.02
	ice_band_contrast = 0.15
	storm_count = 2
	storm_size_min_deg = 3.0
	storm_size_max_deg = 9.0
	storm_stretch = 2.0
	ice_haze_strength = 0.30
	atm_color = PAL.ATM_RIM_ICE
	super()

func _get_planet_texture_size() -> int:
	return 54

func _get_planet_color(_t: float, _x: int, _y: int) -> Color:
	return PAL.ICE_DEEP_BLUE

func _get_ice_base_color() -> Color:
	return PAL.ICE_DEEP_BLUE

func _get_ice_haze_color() -> Color:
	return PAL.ICE_HAZE_WHITE

func _get_ice_storm_dark() -> Color:
	return PAL.ICE_STORM_DARK

func _seed_storms(_seed_val: int):
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	# Great Dark Spot analog — dark oval in the southern hemisphere.
	_storm_lats.append(-0.3)
	_storm_lons.append(0.0)
	_storm_sizes.append(deg_to_rad(9.0))
	_storm_strengths.append(0.55)
	_storm_kinds.append(STORM_DARK)
	# Small white companion methane cloud.
	_storm_lats.append(-0.2)
	_storm_lons.append(0.35)
	_storm_sizes.append(deg_to_rad(3.5))
	_storm_strengths.append(0.30)
	_storm_kinds.append(STORM_WHITE)
