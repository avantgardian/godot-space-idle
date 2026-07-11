extends "res://scripts/orbital_body.gd"

func _ready():
	orbit_radius = 350.0
	orbit_period = 30.0
	start_angle = 0.0
	mass = 1.65e-7
	collision_radius = 18.0
	_trail_max = 450   # half orbit: 30s × 30 pts/s ÷ 2
	_generate_texture()
	_reset()

func _get_planet_texture_size() -> int:
	return 36

func _get_planet_color(t: float, _x: int, _y: int) -> Color:
	var b: float = 0.5 + 0.5 * (1.0 - t)
	var alpha := 1.0
	if t > 0.85:
		alpha = 1.0 - (t - 0.85) / 0.15
	return Color(0.7 * b, 0.7 * b, 0.72 * b, alpha)

func predict_orbit(steps: int = 1200, future_mass: float = -1.0) -> PackedVector2Array:
	if _dead:
		return PackedVector2Array()

	var gm := _initial_gm() * (sun_mass if future_mass < 0.0 else future_mass)
	var sim_pos := _pos
	var sim_vel := _vel
	var dt := 1.0 / 60.0
	var pts := PackedVector2Array()
	pts.resize(steps)
	var hit_radius := sun_collision_r(sun_mass) + collision_radius

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
