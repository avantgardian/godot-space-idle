extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 350.0
	orbit_period = 30.0
	start_angle = 0.0
	mass = 0.055
	collision_radius = 18.0
	_trail_max = 900
	_reset()

func predict_orbit(steps: int = 1200, future_mass: float = -1.0) -> PackedVector2Array:
	if _dead:
		return PackedVector2Array()

	var gm := _initial_gm() * (sun_mass if future_mass < 0.0 else future_mass)
	var sim_pos := _pos
	var sim_vel := _vel
	var dt := 1.0 / 60.0
	var pts := PackedVector2Array()
	pts.resize(steps)
	var hit_radius := (128.0 + sqrt(sun_mass) * 8.0) * 0.85 + 18.0

	for i in range(steps):
		pts[i] = sim_pos
		var r2 := sim_pos.length_squared()
		if r2 < 4.0:
			pts.resize(i + 1)
			break
		if r2 < hit_radius * hit_radius:
			pts.resize(i + 1)
			break
		var r := sqrt(r2)
		var acc := -gm / r2 * sim_pos / r
		sim_vel += acc * dt
		sim_pos += sim_vel * dt

	return pts
