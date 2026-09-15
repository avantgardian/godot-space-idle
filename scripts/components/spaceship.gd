class_name Spaceship
extends Node2D

const MAX_SPEED: float = 300.0
const THRUST_FORCE: float = 160.0
const REVERSE_FORCE: float = 80.0
const ROTATION_SPEED: float = 3.0
const DAMPING: float = 0.8
const COLLISION_RADIUS: float = 14.0

const FIRE_MUZZLE_SPEED: float = 175.0

const SHIP: GDScript = preload("res://scripts/util/ship_palette.gd")
const _ROCKET: GDScript = preload("res://scripts/components/rocket.gd")

# Geometry — all points in local space, nose = -Y (Vector2.UP), tail = +Y.
# Built once at class-load, never allocated inside _draw. Mostly symmetric,
# with one subtly dinged starboard radiator (see _has_ding seam note).
static var _nose_cap: PackedVector2Array = PackedVector2Array(
	[Vector2(0.0, -19.0), Vector2(-4.2, -12.5), Vector2(4.2, -12.5)]
)
static var _fwd_hull: PackedVector2Array = PackedVector2Array(
	[Vector2(-5.6, -13.0), Vector2(5.6, -13.0), Vector2(4.8, -2.2), Vector2(-4.8, -2.2)]
)
static var _mid_hull: PackedVector2Array = PackedVector2Array(
	[Vector2(-5.2, -2.2), Vector2(5.2, -2.2), Vector2(5.0, 8.5), Vector2(-5.0, 8.5)]
)
static var _chamfer_port_fwd: PackedVector2Array = PackedVector2Array(
	[Vector2(-5.6, -13.0), Vector2(-8.2, -10.2), Vector2(-7.0, -2.2), Vector2(-4.8, -2.2)]
)
static var _chamfer_starboard_fwd: PackedVector2Array = PackedVector2Array(
	[Vector2(5.6, -13.0), Vector2(4.8, -2.2), Vector2(7.0, -2.2), Vector2(8.2, -10.2)]
)
static var _radiator_port: PackedVector2Array = PackedVector2Array(
	[Vector2(-9.5, -1.5), Vector2(-6.2, -1.5), Vector2(-6.0, 6.5), Vector2(-9.2, 6.5)]
)
static var _radiator_starboard: PackedVector2Array = PackedVector2Array(
	[Vector2(6.2, -1.5), Vector2(9.5, -1.5), Vector2(9.2, 6.5), Vector2(6.0, 6.5)]
)
static var _spine: PackedVector2Array = PackedVector2Array(
	[Vector2(-1.1, -9.0), Vector2(1.1, -9.0), Vector2(1.1, 8.5), Vector2(-1.1, 8.5)]
)
static var _engine_block: PackedVector2Array = PackedVector2Array(
	[Vector2(-6.0, 8.5), Vector2(6.0, 8.5), Vector2(5.2, 11.8), Vector2(-5.2, 11.8)]
)
static var _bulkhead_stripe_a: PackedVector2Array = PackedVector2Array(
	[Vector2(-5.2, 10.2), Vector2(-2.8, 10.2), Vector2(-1.6, 11.0), Vector2(-4.0, 11.0)]
)
static var _bulkhead_stripe_b: PackedVector2Array = PackedVector2Array(
	[Vector2(0.0, 10.2), Vector2(2.4, 10.2), Vector2(3.6, 11.0), Vector2(1.2, 11.0)]
)
static var _bulkhead_stripe_c: PackedVector2Array = PackedVector2Array(
	[Vector2(3.2, 10.2), Vector2(4.8, 10.2), Vector2(5.0, 11.0), Vector2(3.6, 11.0)]
)
static var _nozzle_port_outer: PackedVector2Array = PackedVector2Array(
	[Vector2(-5.6, 11.8), Vector2(-1.6, 11.8), Vector2(-0.8, 16.6), Vector2(-6.4, 16.6)]
)
static var _nozzle_starboard_outer: PackedVector2Array = PackedVector2Array(
	[Vector2(1.6, 11.8), Vector2(5.6, 11.8), Vector2(6.4, 16.6), Vector2(0.8, 16.6)]
)
static var _cockpit_frame: PackedVector2Array = PackedVector2Array(
	[Vector2(-3.2, -11.2), Vector2(3.2, -11.2), Vector2(2.4, -6.8), Vector2(-2.4, -6.8)]
)
static var _cockpit_glass: PackedVector2Array = PackedVector2Array(
	[Vector2(-2.6, -10.6), Vector2(2.6, -10.6), Vector2(1.9, -7.4), Vector2(-1.9, -7.4)]
)
# Panel seams (drawn as thin lines, not filled) — pairs are line endpoints.
static var _seam_fwd_h: Array[Vector2] = [Vector2(-5.2, -7.0), Vector2(5.2, -7.0)]
static var _seam_mid_h: Array[Vector2] = [Vector2(-5.0, 2.8), Vector2(5.0, 2.8)]
static var _seam_spine_v: Array[Vector2] = [Vector2(0.0, -9.0), Vector2(0.0, 8.5)]

# Pre-baked rivet positions (local space) — small, cheap to draw.
static var _rivets: PackedVector2Array = PackedVector2Array(
	[
		Vector2(-4.6, -11.2),
		Vector2(4.6, -11.2),
		Vector2(-4.6, -4.0),
		Vector2(4.6, -4.0),
		Vector2(-4.8, 1.2),
		Vector2(4.8, 1.2),
		Vector2(-4.6, 6.8),
		Vector2(4.6, 6.8),
		Vector2(-1.1, -6.0),
		Vector2(1.1, -6.0),
		Vector2(-1.1, 0.5),
		Vector2(1.1, 0.5),
		Vector2(-1.1, 6.0),
		Vector2(1.1, 6.0),
	]
)

var mass: float = 0.001
var collision_radius: float = COLLISION_RADIUS
var input_active: bool = false

var _pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _alive: bool = true
var _rocket_in_flight: bool = false

var _thrust_node: _EnginePlumeLayer
var _flicker: float = 0.0
var _nav_phase: float = 0.0
var _sun_local: Vector2 = Vector2(-1.0, 0.0)
var _ship_seed: int = 1337

# Soot / wear chips (generated in _ready, deterministic by ship seed).
var _chips: PackedVector2Array = PackedVector2Array()
var _chip_colors: PackedColorArray = PackedColorArray()
var _streaks: Array[PackedVector2Array] = []


func _ready() -> void:
	_thrust_node = _EnginePlumeLayer.new()
	_thrust_node.name = "EnginePlume"
	add_child(_thrust_node)
	_thrust_node.visible = false

	_generate_wear()
	position = _pos


func init(start_pos: Vector2) -> void:
	_pos = start_pos
	position = start_pos
	_update_sun_dir()


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	if input_active:
		var rotate_left: bool = Input.is_action_pressed("ship_rotate_left")
		var rotate_right: bool = Input.is_action_pressed("ship_rotate_right")
		var thrust_forward: bool = Input.is_action_pressed("ship_thrust_forward")
		var thrust_reverse: bool = Input.is_action_pressed("ship_thrust_reverse")

		if rotate_left and not rotate_right:
			_angle -= ROTATION_SPEED * delta
		elif rotate_right and not rotate_left:
			_angle += ROTATION_SPEED * delta

		var thrust_dir: Vector2 = Vector2.UP.rotated(_angle)

		var thrusting: bool = false
		if thrust_forward:
			_vel += thrust_dir * THRUST_FORCE * delta
			thrusting = true
		if thrust_reverse:
			_vel -= thrust_dir * REVERSE_FORCE * delta
			thrusting = true

		_thrust_node.visible = thrusting
		_thrust_node.thrusting = thrusting
	else:
		_thrust_node.visible = false
		_thrust_node.thrusting = false

	_vel *= max(1.0 - DAMPING * delta, 0.0)

	var speed: float = _vel.length()
	if speed > MAX_SPEED:
		_vel = _vel.normalized() * MAX_SPEED

	_pos += _vel * delta
	position = _pos
	rotation = _angle

	_flicker += delta * 22.0
	_thrust_node._phase = _flicker
	_thrust_node.vel_len = _vel.length()
	_thrust_node.queue_redraw()

	_nav_phase += delta * 2.2
	_update_sun_dir()

	queue_redraw()


func _update_sun_dir() -> void:
	var r2: float = _pos.length_squared()
	if r2 < 1.0:
		_sun_local = Vector2(0.0, -1.0).rotated(-_angle)
	else:
		var sun_world: Vector2 = (-_pos).normalized()
		_sun_local = sun_world.rotated(-_angle)


func enforce_sun_barrier(min_dist: float) -> void:
	var r: float = _pos.length()
	if r < min_dist:
		if r < 0.01:
			_pos = Vector2(min_dist, 0.0)
		else:
			_pos = _pos.normalized() * min_dist
		position = _pos
		var radial_dir: Vector2 = _pos.normalized()
		var radial_vel: float = _vel.dot(radial_dir)
		if radial_vel < 0.0:
			_vel -= radial_dir * radial_vel


func is_alive() -> bool:
	return _alive


func is_dead() -> bool:
	return not _alive


func get_vel() -> Vector2:
	return _vel


func set_vel(v: Vector2) -> void:
	_vel = v


func try_fire(target: Node2D) -> Rocket:
	if _rocket_in_flight or not _alive:
		return null
	_rocket_in_flight = true
	@warning_ignore("unsafe_cast")
	var rocket: Rocket = _ROCKET.new() as Rocket
	var muzzle_vel: Vector2 = Vector2.UP.rotated(_angle) * FIRE_MUZZLE_SPEED
	rocket.init(_pos, _vel + muzzle_vel, target)
	rocket.resolved.connect(_on_rocket_resolved, CONNECT_ONE_SHOT)
	return rocket


func _on_rocket_resolved(_reason: Rocket.Resolution) -> void:
	_rocket_in_flight = false


func disable() -> void:
	_alive = false
	visible = false


func _generate_wear() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _ship_seed * 7919 + 3
	_chips.clear()
	_chip_colors.clear()
	# Paint chips on leading edges (nose, chamfers, radiator tips).
	var chip_count: int = 16
	for i: int in range(chip_count):
		var edge_t: float = rng.randf()
		var px: float = 0.0
		var py: float = 0.0
		if i < 5:
			# Nose / forward chamfers
			px = rng.randf_range(-7.2, 7.2)
			py = rng.randf_range(-14.0, -8.0)
		elif i < 11:
			# Mid hull sides
			var side: float = -1.0 if rng.randf() < 0.5 else 1.0
			px = side * rng.randf_range(4.8, 5.6)
			py = rng.randf_range(-6.0, 6.0)
		else:
			# Radiator tips (subtle asymmetry bait)
			var side2: float = -1.0 if rng.randf() < 0.5 else 1.0
			px = side2 * rng.randf_range(8.5, 9.4)
			py = rng.randf_range(-0.5, 6.0)
		_chips.append(Vector2(px, py))
		var is_primer: bool = rng.randf() < 0.55
		@warning_ignore("unsafe_property_access")
		var col: Color = SHIP.PRIMER_RED as Color if is_primer else SHIP.METAL_DARK
		_chip_colors.append(col)

	# Soot streaks — 3 vertical feathered quads down the mid hull.
	_streaks.clear()
	for s: int in range(3):
		var cx: float = [-2.6, 0.8, 3.1][s]
		var w: float = [1.2, 0.9, 1.0][s]
		var quad: PackedVector2Array = PackedVector2Array(
			[
				Vector2(cx - w * 0.5, 2.6),
				Vector2(cx + w * 0.5, 2.6),
				Vector2(cx + w * 0.35, 9.6),
				Vector2(cx - w * 0.35, 9.6),
			]
		)
		_streaks.append(quad)


func _lit_color(base: Color, n2: Vector2, tilt_sin: float) -> Color:
	# 3D facet normal is (n2.x * sin, n2.y * sin, cos). L is (sun.x, sun.y, 0).
	# Diffuse = max(dot(N, L), 0) = max(sin * dot(n2, sun), 0). Night side falls to ambient.
	@warning_ignore("unsafe_property_access", "unsafe_cast")
	var ambient: float = SHIP.SHIP_AMBIENT as float
	var cos_t_unused: float = sqrt(maxf(1.0 - tilt_sin * tilt_sin, 0.0))
	var ndotl: float = 0.0
	if tilt_sin > 0.001:
		ndotl = maxf(n2.dot(_sun_local), 0.0) * tilt_sin
	# Top-facing facets (tilt 0) stay at ambient only; side walls get full swing.
	var light: float = ambient + (1.0 - ambient) * ndotl
	light = clampf(light, 0.0, 1.0)
	return Color(base.r * light, base.g * light, base.b * light, base.a)


func _spec_add(n2: Vector2, tilt_sin: float) -> float:
	# Cheap Blinn-Phong: H = normalize(L + V), V=(0,0,1), |H|=sqrt(2).
	# dot(N,H) = (sin*dot(n2,L) + cos) / sqrt(2). Only valid when sun-facing.
	if tilt_sin < 0.35:
		return 0.0
	var ndotl_raw: float = n2.dot(_sun_local)
	if ndotl_raw < 0.15:
		return 0.0
	var cos_t: float = sqrt(maxf(1.0 - tilt_sin * tilt_sin, 0.0))
	var h_dot_n: float = (tilt_sin * ndotl_raw + cos_t) / 1.41421356
	h_dot_n = clampf(h_dot_n, 0.0, 1.0)
	@warning_ignore("unsafe_property_access", "unsafe_cast")
	var powder: float = SHIP.SPEC_POWER_ALU as float
	@warning_ignore("unsafe_property_access", "unsafe_cast")
	var intens: float = SHIP.SPEC_INTENSITY_ALU as float
	var spec: float = pow(h_dot_n, powder) * intens * clampf((ndotl_raw - 0.15) / 0.85, 0.0, 1.0)
	return clampf(spec, 0.0, 1.0)


# ---------------------------------------------------------------------------
# Main hull rendering — flat-shaded plates + seams + wear + glass + nav lights
# ---------------------------------------------------------------------------


func _draw() -> void:
	# --- Hull plates (sun-driven) — order back-to-front so seams stay crisp.
	# Engine block (dark steel, vertical sides => tilt 1)
	@warning_ignore("unsafe_property_access")
	var metal_dark: Color = SHIP.METAL_DARK as Color
	var engine_base: Color = _lit_color(metal_dark, Vector2(0.0, 1.0), 0.0)
	draw_colored_polygon(_engine_block, engine_base)

	# Radiators (aluminum, slight tilt so they catch glancing sun)
	@warning_ignore("unsafe_property_access")
	var alu: Color = SHIP.METAL_ALUMINUM as Color
	var rad_n_port: Vector2 = Vector2(-0.92, 0.35)
	var rad_n_star: Vector2 = Vector2(0.92, 0.35)
	var rad_port_c: Color = _lit_color(alu, rad_n_port, 0.55)
	var rad_star_c: Color = _lit_color(alu, rad_n_star, 0.55)
	# Ding the starboard radiator corner ever so slightly: pull one vertex inward 0.6px
	# (subtle asymmetry, still symmetric at a glance per spec).
	var rad_star_dinged: PackedVector2Array = PackedVector2Array(
		[Vector2(6.2, -1.5), Vector2(9.5, -1.5), Vector2(9.2, 6.5), Vector2(6.0, 6.5)]
	)
	rad_star_dinged[1] = Vector2(8.9, -0.9)
	draw_colored_polygon(_radiator_port, rad_port_c)
	draw_colored_polygon(rad_star_dinged, rad_star_c)

	# Chamfers — the hero angled surfaces (high tilt, strong sun response)
	var cham_port_n: Vector2 = Vector2(-0.78, -0.62).normalized()
	var cham_star_n: Vector2 = Vector2(0.78, -0.62).normalized()
	@warning_ignore("unsafe_property_access")
	var hull_paint: Color = SHIP.HULL_PAINT as Color
	var cham_port_c: Color = _lit_color(hull_paint, cham_port_n, 0.85)
	var cham_star_c: Color = _lit_color(hull_paint, cham_star_n, 0.85)
	draw_colored_polygon(_chamfer_port_fwd, cham_port_c)
	draw_colored_polygon(_chamfer_starboard_fwd, cham_star_c)
	# Chamfer specular streak (thin highlight when sun skims the bevel)
	var spec_p: float = _spec_add(cham_port_n, 0.85)
	var spec_s: float = _spec_add(cham_star_n, 0.85)
	if spec_p > 0.08:
		var a: float = clampf(spec_p * 1.4, 0.0, 0.55)
		draw_polyline(
			PackedVector2Array([Vector2(-5.6, -13.0), Vector2(-7.0, -2.2)]),
			Color(1.0, 1.0, 1.0, a),
			0.9,
			true
		)
	if spec_s > 0.08:
		var a2: float = clampf(spec_s * 1.4, 0.0, 0.55)
		draw_polyline(
			PackedVector2Array([Vector2(5.6, -13.0), Vector2(7.0, -2.2)]),
			Color(1.0, 1.0, 1.0, a2),
			0.9,
			true
		)

	# Forward + mid hull (white paint, roof tilt 0 => ambient only + AO)
	var fwd_c: Color = _lit_color(hull_paint, Vector2(0.0, -1.0), 0.0)
	var mid_c: Color = _lit_color(hull_paint, Vector2(0.0, 1.0), 0.0)
	# Slight AO under spine (mid hull a touch darker where truss shadows)
	mid_c = Color(mid_c.r * 0.94, mid_c.g * 0.94, mid_c.b * 0.94, mid_c.a)
	draw_colored_polygon(_fwd_hull, fwd_c)
	draw_colored_polygon(_mid_hull, mid_c)

	# Nose cap (sharply forward-tilted, catches head-on sun)
	@warning_ignore("unsafe_property_access")
	var nose_n: Vector2 = Vector2(0.0, -1.0)
	var nose_c: Color = _lit_color(hull_paint, nose_n, 0.92)
	draw_colored_polygon(_nose_cap, nose_c)
	var nose_spec: float = _spec_add(nose_n, 0.92)
	if nose_spec > 0.10:
		var na: float = clampf(nose_spec * 1.2, 0.0, 0.42)
		draw_polyline(
			PackedVector2Array([Vector2(-4.2, -12.5), Vector2(0.0, -19.0), Vector2(4.2, -12.5)]),
			Color(1.0, 1.0, 1.0, na),
			0.85,
			true
		)

	# Dorsal spine / truss (dark, with AO)
	@warning_ignore("unsafe_property_access")
	var spine_c: Color = _lit_color(SHIP.METAL_DARK_HI as Color, Vector2(0.0, 1.0), 0.0)
	# Spine sits on top, so not darkened; add slight center highlight
	draw_colored_polygon(_spine, spine_c)
	# Truss cross-ties (two short horizontals)
	@warning_ignore("unsafe_property_access")
	var truss_line: Color = Color(
		(SHIP.METAL_DARK as Color).r * 0.6,
		(SHIP.METAL_DARK as Color).g * 0.6,
		(SHIP.METAL_DARK as Color).b * 0.6,
		1.0
	)
	draw_line(Vector2(-1.1, -4.5), Vector2(1.1, -4.5), truss_line, 0.7, true)
	draw_line(Vector2(-1.1, 3.2), Vector2(1.1, 3.2), truss_line, 0.7, true)

	# Panel seams (thin, always visible)
	@warning_ignore("unsafe_property_access")
	var seam_c: Color = SHIP.HULL_PANEL_LINE as Color
	draw_line(_seam_fwd_h[0], _seam_fwd_h[1], seam_c, 0.7, true)
	draw_line(_seam_mid_h[0], _seam_mid_h[1], seam_c, 0.7, true)
	draw_line(_seam_spine_v[0], _seam_spine_v[1], seam_c, 0.55, true)
	# Chamfer seams
	draw_line(Vector2(-5.6, -13.0), Vector2(-4.8, -2.2), seam_c, 0.6, true)
	draw_line(Vector2(5.6, -13.0), Vector2(4.8, -2.2), seam_c, 0.6, true)
	# Radiator seams
	draw_line(Vector2(-6.2, -1.5), Vector2(-6.0, 6.5), seam_c, 0.5, true)
	draw_line(Vector2(6.2, -1.5), Vector2(6.0, 6.5), seam_c, 0.5, true)

	# Rivets — tiny aluminum dots with a sun-offset highlight
	for rv: Vector2 in _rivets:
		draw_circle(rv, 0.65, alu)
		# Highlight dot 0.4px toward sun (sells metallic)
		if _sun_local.length_squared() > 0.01:
			var hi_off: Vector2 = _sun_local * 0.35
			@warning_ignore("unsafe_property_access")
			draw_circle(rv + hi_off, 0.28, SHIP.METAL_ALUMINUM_HI as Color)

	# Wear: soot streaks (feathered, not sun-affected) + paint chips
	for quad: PackedVector2Array in _streaks:
		@warning_ignore("unsafe_property_access")
		draw_colored_polygon(quad, SHIP.SOOT_MID as Color)
	# Paint chips — small triangles where primer shows
	for i: int in range(_chips.size()):
		var p: Vector2 = _chips[i]
		var c: Color = _chip_colors[i]
		var s: float = 0.55 + float(i % 3) * 0.22
		var tri: PackedVector2Array = PackedVector2Array(
			[
				Vector2(p.x, p.y - s * 0.6),
				Vector2(p.x - s * 0.5, p.y + s * 0.5),
				Vector2(p.x + s * 0.5, p.y + s * 0.45)
			]
		)
		draw_colored_polygon(tri, c)

	# Bulkhead hazard stripes (industrial read, aft)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(_bulkhead_stripe_a, SHIP.WARNING_STRIPE as Color)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(_bulkhead_stripe_b, SHIP.WARNING_STRIPE as Color)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(
		_bulkhead_stripe_c,
		Color(
			(SHIP.WARNING_STRIPE as Color).r * 0.88,
			(SHIP.WARNING_STRIPE as Color).g * 0.88,
			(SHIP.WARNING_STRIPE as Color).b * 0.88,
			1.0
		)
	)
	# Dark between stripes is the engine block itself already; add two more dark dividers for contrast
	draw_line(Vector2(-2.8, 10.2), Vector2(-1.6, 11.0), truss_line, 0.6, true)
	draw_line(Vector2(2.4, 10.2), Vector2(3.6, 11.0), truss_line, 0.6, true)

	# Nozzle outer shells (gunmetal, slight sun)
	var noz_n_port: Vector2 = Vector2(-0.35, 1.0).normalized()
	var noz_n_star: Vector2 = Vector2(0.35, 1.0).normalized()
	@warning_ignore("unsafe_property_access")
	var noz_base: Color = SHIP.SOOT_DARK as Color
	var noz_pc: Color = _lit_color(noz_base, noz_n_port, 0.65)
	var noz_sc: Color = _lit_color(noz_base, noz_n_star, 0.65)
	draw_colored_polygon(_nozzle_port_outer, noz_pc)
	draw_colored_polygon(_nozzle_starboard_outer, noz_sc)
	# Nozzle throats (warm, emissive-ish — not sun-driven)
	var throat_port: PackedVector2Array = PackedVector2Array(
		[Vector2(-4.8, 12.4), Vector2(-2.4, 12.4), Vector2(-1.8, 15.2), Vector2(-5.4, 15.2)]
	)
	var throat_star: PackedVector2Array = PackedVector2Array(
		[Vector2(2.4, 12.4), Vector2(4.8, 12.4), Vector2(5.4, 15.2), Vector2(1.8, 15.2)]
	)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(throat_port, SHIP.NOZZLE_INNER as Color)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(throat_star, SHIP.NOZZLE_INNER as Color)
	# Throat hotspot (small white quad at top of bell, where plasma would be)
	var hot_p: PackedVector2Array = PackedVector2Array(
		[Vector2(-4.4, 12.4), Vector2(-2.8, 12.4), Vector2(-2.5, 13.6), Vector2(-4.7, 13.6)]
	)
	var hot_s: PackedVector2Array = PackedVector2Array(
		[Vector2(2.8, 12.4), Vector2(4.4, 12.4), Vector2(4.7, 13.6), Vector2(2.5, 13.6)]
	)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(hot_p, SHIP.NOZZLE_THROAT as Color)
	@warning_ignore("unsafe_property_access")
	draw_colored_polygon(hot_s, SHIP.NOZZLE_THROAT as Color)

	# Cockpit — frame then glass (glass has own fresnel-ish specular)
	@warning_ignore("unsafe_property_access")
	var frame_c: Color = _lit_color(SHIP.METAL_DARK_HI as Color, Vector2(0.0, -1.0), 0.35)
	draw_colored_polygon(_cockpit_frame, frame_c)
	# Glass: interpolate between tint and shadow by sun facing + selected glow
	var glass_ndotl: float = max(Vector2(0.0, -1.0).dot(_sun_local) * 0.65, 0.0)
	@warning_ignore("unsafe_property_access", "unsafe_cast")
	var gt: Color = SHIP.GLASS_TINT as Color
	@warning_ignore("unsafe_property_access", "unsafe_cast")
	var gs: Color = SHIP.GLASS_TINT_SHADOW as Color
	var glass_base: Color = gt.lerp(gs, 1.0 - clampf(glass_ndotl * 1.2 + 0.18, 0.0, 1.0))
	# When selected (input_active), cockpit interior is lit — glass appears warmer / more transmissive
	if input_active:
		# Slight warm boost as if interior flood is on
		glass_base = Color(
			clampf(glass_base.r * 1.18, 0.0, 1.0),
			clampf(glass_base.g * 1.14, 0.0, 1.0),
			clampf(glass_base.b * 1.08, 0.0, 1.0),
			glass_base.a
		)
	draw_colored_polygon(_cockpit_glass, glass_base)
	# Glass specular streak — diagonal glint when sun is not dead-ahead (sells "angled glass")
	var glass_spec_n: Vector2 = Vector2(0.28, -0.96).normalized()
	var glass_spec: float = _spec_add(glass_spec_n, 0.72)
	# Also add a cheaper 2D streak independent of spec for readability at distance
	var glint_alpha: float = clampf(glass_ndotl * 0.45 + glass_spec * 1.6, 0.0, 0.85)
	if glint_alpha > 0.06:
		@warning_ignore("unsafe_property_access")
		var glint_c: Color = Color(
			(SHIP.GLASS_SPEC as Color).r,
			(SHIP.GLASS_SPEC as Color).g,
			(SHIP.GLASS_SPEC as Color).b,
			glint_alpha
		)
		draw_line(Vector2(-2.1, -10.0), Vector2(0.6, -7.9), glint_c, 0.85, true)
	# Cockpit interior divider (center mullion) and faint interior glow when selected
	draw_line(Vector2(0.0, -11.0), Vector2(0.0, -7.2), frame_c, 0.9, true)
	if input_active:
		@warning_ignore("unsafe_property_access")
		draw_colored_polygon(_cockpit_glass, SHIP.COCKPIT_GLOW as Color)

	# Whip antenna (dorsal, kinked — story piece)
	var ant_base: Vector2 = Vector2(0.0, -9.2)
	var ant_kink: Vector2 = Vector2(0.35, -16.5)
	var ant_tip: Vector2 = Vector2(-0.55, -21.8)
	@warning_ignore("unsafe_property_access")
	var ant_c: Color = SHIP.METAL_DARK as Color
	draw_line(ant_base, ant_kink, ant_c, 0.75, true)
	draw_line(ant_kink, ant_tip, ant_c, 0.65, true)
	draw_circle(ant_tip, 0.55, ant_c)

	# Diegetic nav lights — natural highlight, replaces the neon ring.
	# Port (red) on port radiator tip, starboard (green) on starboard tip, stern white on engine block.
	# Blink pattern: unselected = dim steady; selected = bright blink (1.1s red, offset green).
	var port_pos: Vector2 = Vector2(-9.5, -1.5)
	var star_pos: Vector2 = Vector2(9.5, -1.5)
	var stern_pos: Vector2 = Vector2(0.0, 12.2)
	var port_on: bool = false
	var star_on: bool = false
	var stern_on: bool = false
	if input_active:
		port_on = sin(_nav_phase) > 0.0
		star_on = sin(_nav_phase + PI * 0.65) > 0.0
		stern_on = sin(_nav_phase * 1.35) > 0.0
	else:
		# Dormant: slow, dim pulse so ship still findable but not shouting
		port_on = sin(_nav_phase * 0.45) > 0.35
		star_on = sin(_nav_phase * 0.45 + 1.1) > 0.35
		stern_on = false

	@warning_ignore("unsafe_property_access")
	var nav_r: Color = SHIP.NAV_RED as Color if port_on else SHIP.NAV_RED_DIM
	@warning_ignore("unsafe_property_access")
	var nav_g: Color = SHIP.NAV_GREEN as Color if star_on else SHIP.NAV_GREEN_DIM
	@warning_ignore("unsafe_property_access")
	var nav_w: Color = SHIP.NAV_WHITE as Color if stern_on else SHIP.NAV_WHITE_DIM
	if not input_active:
		# Dormant: mute the "on" to half-bright so it doesn't compete with engine
		if port_on:
			nav_r = Color(nav_r.r * 0.62, nav_r.g * 0.62, nav_r.b * 0.62, 0.72)
		if star_on:
			nav_g = Color(nav_g.r * 0.62, nav_g.g * 0.62, nav_g.b * 0.62, 0.72)

	draw_circle(port_pos, 1.15, nav_r)
	draw_circle(star_pos, 1.15, nav_g)
	# Stern white is smaller, only when selected
	if input_active or stern_on:
		draw_circle(stern_pos, 0.85, nav_w)
	# Tiny highlight on the lens toward sun (sells glass)
	if _sun_local.length_squared() > 0.01:
		var sun_hi: Vector2 = _sun_local * 0.42
		draw_circle(port_pos + sun_hi * 0.5, 0.35, Color(1.0, 1.0, 1.0, 0.85))
		draw_circle(star_pos + sun_hi * 0.5, 0.35, Color(1.0, 1.0, 1.0, 0.85))


# ---------------------------------------------------------------------------
# Additive plume layer — hot core → blue → soot orange, flicker via _phase.
# Stays additive because it is emissive. Shape is trapezoidal exhaust, not a flat poly.
# ---------------------------------------------------------------------------


class _EnginePlumeLayer:
	extends Node2D
	# gdlint: disable=duplicated-load
	const SHIP: GDScript = preload("res://scripts/util/ship_palette.gd")
	var thrusting: bool = false
	var vel_len: float = 0.0
	var _phase: float = 0.0
	var _buf_soot: PackedVector2Array = PackedVector2Array()
	var _buf_outer: PackedVector2Array = PackedVector2Array()
	var _buf_mid: PackedVector2Array = PackedVector2Array()
	var _buf_core: PackedVector2Array = PackedVector2Array()
	var _buf_hot: PackedVector2Array = PackedVector2Array()
	var _buf_diamond: PackedVector2Array = PackedVector2Array()

	func _init() -> void:
		var mat: CanvasItemMaterial = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		_buf_soot.resize(4)
		_buf_outer.resize(4)
		_buf_mid.resize(4)
		_buf_core.resize(4)
		_buf_hot.resize(4)
		_buf_diamond.resize(4)

	func _hash01(x: float) -> float:
		return fposmod(sin(x * 127.1) * 43758.5453, 1.0)

	func _draw() -> void:
		if not thrusting:
			return
		var ports: Array[Vector2] = [Vector2(-3.6, 14.8), Vector2(3.6, 14.8)]
		# Speed-mapped base length: idle thrust still long, fast ship slightly longer.
		var speed_t: float = clampf(vel_len / 300.0, 0.0, 1.0)
		for port: Vector2 in ports:
			var flicker_a: float = sin(_phase * 0.9 + port.x * 1.7) * 0.16 + 1.0
			var flicker_b: float = sin(_phase * 1.65 - port.x * 2.1) * 0.12 + 1.0
			var flicker: float = flicker_a * 0.7 + flicker_b * 0.3
			var len_soot: float = lerpf(16.0, 24.0, speed_t) * flicker * 1.05
			var len_outer: float = lerpf(14.0, 20.5, speed_t) * flicker
			var len_mid: float = lerpf(11.0, 16.0, speed_t) * flicker * 0.96
			var len_core: float = lerpf(7.5, 11.5, speed_t) * flicker * 0.92
			var len_hot: float = lerpf(4.5, 7.0, speed_t) * flicker * 0.9
			var w_soot: float = 4.2
			var w_outer: float = 3.2
			var w_mid: float = 1.9
			var w_core: float = 0.95
			var w_hot: float = 0.42
			# Edge wobble — different phase per edge so nozzle doesn't look symmetric.
			var wob_l: float = sin(_phase * 2.3 + port.x * 0.9) * 0.65
			var wob_r: float = sin(_phase * 2.7 - port.x * 1.1) * 0.65
			var wob_l2: float = sin(_phase * 3.1 + port.x * 1.3) * 0.38
			var wob_r2: float = sin(_phase * 2.9 - port.x * 0.8) * 0.38

			# Soot feather (outermost, very soft, gritty dark orange).
			_buf_soot[0] = port + Vector2(-w_soot + wob_l * 0.5, 0.0)
			_buf_soot[1] = port + Vector2(w_soot + wob_r * 0.5, 0.0)
			_buf_soot[2] = port + Vector2(w_soot * 0.48 + wob_r, len_soot)
			_buf_soot[3] = port + Vector2(-w_soot * 0.48 + wob_l, len_soot)
			@warning_ignore("unsafe_property_access")
			draw_colored_polygon(_buf_soot, SHIP.ENGINE_OUTER_DIM as Color)

			_buf_outer[0] = port + Vector2(-w_outer, 0.0)
			_buf_outer[1] = port + Vector2(w_outer, 0.0)
			_buf_outer[2] = port + Vector2(w_outer * 0.55 + wob_r, len_outer)
			_buf_outer[3] = port + Vector2(-w_outer * 0.55 + wob_l, len_outer)
			@warning_ignore("unsafe_property_access")
			draw_colored_polygon(_buf_outer, SHIP.ENGINE_OUTER as Color)

			_buf_mid[0] = port + Vector2(-w_mid, 0.0)
			_buf_mid[1] = port + Vector2(w_mid, 0.0)
			_buf_mid[2] = port + Vector2(w_mid * 0.5 + wob_r2, len_mid)
			_buf_mid[3] = port + Vector2(-w_mid * 0.5 + wob_l2, len_mid)
			@warning_ignore("unsafe_property_access")
			draw_colored_polygon(_buf_mid, SHIP.ENGINE_MID as Color)

			_buf_core[0] = port + Vector2(-w_core, 0.0)
			_buf_core[1] = port + Vector2(w_core, 0.0)
			_buf_core[2] = port + Vector2(w_core * 0.45 + wob_r2 * 0.5, len_core)
			_buf_core[3] = port + Vector2(-w_core * 0.45 + wob_l2 * 0.5, len_core)
			@warning_ignore("unsafe_property_access")
			draw_colored_polygon(_buf_core, SHIP.ENGINE_CORE as Color)

			_buf_hot[0] = port + Vector2(-w_hot, 0.0)
			_buf_hot[1] = port + Vector2(w_hot, 0.0)
			_buf_hot[2] = port + Vector2(w_hot * 0.35, len_hot)
			_buf_hot[3] = port + Vector2(-w_hot * 0.35, len_hot)
			draw_colored_polygon(_buf_hot, Color(1.0, 1.0, 1.0, 0.92))

			# Mach diamonds — two bright bands (shock cells) along the core.
			for d: int in range(2):
				var t: float = 0.32 + float(d) * 0.32
				var y0: float = len_core * t - 1.4
				var y1: float = len_core * t + 1.4
				var w_at: float = lerpf(w_core * 0.42, w_core * 0.20, t)
				var pulse: float = 0.55 + sin(_phase * 4.2 + float(d) * 1.9) * 0.35
				pulse = clampf(pulse, 0.0, 1.0)
				_buf_diamond[0] = port + Vector2(-w_at, y0)
				_buf_diamond[1] = port + Vector2(w_at, y0)
				_buf_diamond[2] = port + Vector2(w_at * 0.85, y1)
				_buf_diamond[3] = port + Vector2(-w_at * 0.85, y1)
				var dcol: Color = Color(1.0, 1.0, 1.0, 0.38 * pulse)
				draw_colored_polygon(_buf_diamond, dcol)

			# Hull spill — soft glow on the nozzle lip (heat wash on METAL_DARK).
			var spill_r: float = 3.2 + sin(_phase * 2.0 + port.x) * 0.45
			draw_circle(port + Vector2(0.0, -0.8), spill_r, Color(0.40, 0.72, 1.0, 0.14))
			draw_circle(port + Vector2(0.0, -0.6), spill_r * 0.55, Color(1.0, 0.96, 0.88, 0.10))

			# Gritty spark — occasional hot particle spitting from the throat.
			var spark_hash: float = _hash01(_phase * 0.85 + port.x * 17.3)
			if spark_hash > 0.88:
				var sy: float = len_core * (0.25 + _hash01(_phase * 1.3 + port.x * 9.1) * 0.55)
				var sx: float = (_hash01(_phase * 2.1 + port.x * 23.7) - 0.5) * w_core * 1.6
				var spark_a: float = 0.75 + _hash01(_phase * 3.7 + port.x * 11.1) * 0.25
				draw_circle(port + Vector2(sx, sy), 0.85, Color(1.0, 0.82, 0.32, spark_a))
				draw_circle(port + Vector2(sx, sy), 0.45, Color(1.0, 1.0, 1.0, 0.95))
