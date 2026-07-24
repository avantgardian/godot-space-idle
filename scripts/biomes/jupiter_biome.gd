class_name JupiterBiomeConfig
extends GasGiantBiomeConfig

func seed_features(seed_val: int) -> void:
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	var count: int = clampi(storm_count, 0, _MAX_STORMS)
	if count == 0:
		return
	_storm_lats.append(-0.5)
	_storm_lons.append(0.0)
	_storm_sizes.append(deg_to_rad(10.0))
	_storm_strengths.append(0.60)
	_storm_kinds.append(STORM_RUST)
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
