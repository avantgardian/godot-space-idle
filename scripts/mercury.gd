extends OrbitalBody

var planet_name: String = "Mercury"
var planet_color: Color = Color(0.7, 0.7, 0.7)
var planet_speed: float = 47.4

func _ready():
	super()

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
