extends OrbitalBody

func _ready():
	planet_name = "Venus"
	planet_color = Color(0.95, 0.85, 0.5, 1.0)
	collision_flash = 0.8
	collision_ring_color = Color(1, 0.8, 0.4, 0.6)
	collision_ring_width = 3.0
	collision_ring_segments = 64
	collision_ring_timer = 1.2
	use_shader = true
	planet_type = &"greenhouse"
	rotation_rate = 0.08  # animated cloud bands visible (~79s full rotation)
	cloud_swirl_amp = 0.15
	cloud_swirl_freq = 6.0
	cloud_contrast = 0.6
	limb_brighten = 0.3
	# surface_lava_leak omitted — inherits @export default (0.0) so the
	# editor export can be set non-zero for QA testing (lava leak spots).
	atm_color = PAL.ATM_RIM_VENUS
	super()

func _get_planet_texture_size() -> int:
	return 44

func _get_greenhouse_cloud_hi() -> Color:
	return PAL.VENUS_CLOUD_HI

func _get_greenhouse_cloud_lo() -> Color:
	return PAL.VENUS_CLOUD_LO