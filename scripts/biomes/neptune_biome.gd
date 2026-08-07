class_name NeptuneBiomeConfig
extends IceGiantBiomeConfig


func seed_features(_seed_val: int) -> void:
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	_storm_lats.append(-0.3)
	_storm_lons.append(0.0)
	_storm_sizes.append(deg_to_rad(9.0))
	_storm_strengths.append(0.55)
	_storm_kinds.append(STORM_DARK)
	_storm_lats.append(-0.2)
	_storm_lons.append(0.35)
	_storm_sizes.append(deg_to_rad(3.5))
	_storm_strengths.append(0.30)
	_storm_kinds.append(STORM_WHITE)
