extends OrbitalBody

func _ready():
	planet_name = "Jupiter"
	planet_color = Color(0.85, 0.6, 0.3)
	collision_flash = 2.0
	collision_ring_color = Color(0.85, 0.6, 0.3, 0.9)
	collision_ring_width = 6.0
	collision_ring_segments = 96
	collision_ring_timer = 2.5
	use_shader = true
	planet_type = &"gas_giant"
	planet_color = PAL.GAS_BAND_TAN_HI
	rotation_rate = 0.4
	band_count = 12
	band_sharp = 0.15
	shear_amp = 0.10
	band_warp = 0.05
	storm_stretch = 1.5
	storm_count = 4
	storm_size_min_deg = 3.5
	storm_size_max_deg = 8.0
	super()

func _get_planet_texture_size() -> int:
	return 100

func _get_gas_band_hi() -> Color:
	return PAL.GAS_BAND_TAN_HI

func _get_gas_band_lo() -> Color:
	return PAL.GAS_BAND_TAN_LO

func _seed_storms(seed_val: int):
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	var count: int = clamp(storm_count, 0, _MAX_CRATERS)
	if count == 0:
		return
	# Great Red Spot analog — rust oval in the south tropical zone,
	# larger than random storms and fixed position.
	_storm_lats.append(-0.5)        # ~22 deg S (south tropical zone)
	_storm_lons.append(0.0)
	_storm_sizes.append(deg_to_rad(10.0))
	_storm_strengths.append(0.60)
	_storm_kinds.append(STORM_RUST)
	# Remaining 2–3 white ovals placed randomly by seed.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 53 + 11
	for i in range(1, count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(storm_size_min_deg, storm_size_max_deg))
		var strength := rng.randf_range(0.35, 0.60)
		_storm_lats.append(lat)
		_storm_lons.append(lon)
		_storm_sizes.append(size)
		_storm_strengths.append(strength)
		_storm_kinds.append(STORM_WHITE)
