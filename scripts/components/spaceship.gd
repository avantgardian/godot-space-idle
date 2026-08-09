class_name Spaceship
extends Node2D

const MAX_SPEED: float = 300.0
const THRUST_FORCE: float = 160.0
const REVERSE_FORCE: float = 80.0
const ROTATION_SPEED: float = 3.0
const DAMPING: float = 0.8
const COLLISION_RADIUS: float = 14.0

# TRON palette + neon drawing helpers — see scripts/tron_palette.gd and
# scripts/draw_utils.gd. All visual tokens live there; this file should not
# introduce new inline colors.
const FIRE_COOLDOWN: float = 10.0
const FIRE_MUZZLE_SPEED: float = 175.0

const PAL := preload("res://scripts/util/tron_palette.gd")
const DU := preload("res://scripts/util/draw_utils.gd")
const _ROCKET := preload("res://scripts/components/rocket.gd")
const _PULSE_SPEED: float = PAL.RING_PULSE_SPEED  # rad/s pulsation when not selected

# Constant geometry arrays — built once at class-load time, never
# allocated inside _draw. Pointed nose up, swept-back wings, twin engine
# pods, notched tail. Closed polylines (last point == first).
static var _hull_points := PackedVector2Array(
	[
		Vector2(0.0, -18.0),
		Vector2(-5.0, -8.0),
		Vector2(-13.0, 6.0),
		Vector2(-9.0, 7.0),
		Vector2(-9.0, 11.0),
		Vector2(-5.0, 11.0),
		Vector2(-5.0, 7.0),
		Vector2(0.0, 9.0),
		Vector2(5.0, 7.0),
		Vector2(5.0, 11.0),
		Vector2(9.0, 11.0),
		Vector2(9.0, 7.0),
		Vector2(13.0, 6.0),
		Vector2(5.0, -8.0),
		Vector2(0.0, -18.0),
	]
)

static var _accent_left := PackedVector2Array(
	[
		Vector2(2.0, -6.0),
		Vector2(4.5, 1.5),
		Vector2(2.5, 1.5),
		Vector2(-1.0, -6.0),
		Vector2(2.0, -6.0),
	]
)

static var _accent_right := PackedVector2Array(
	[
		Vector2(-2.0, -6.0),
		Vector2(-4.5, 1.5),
		Vector2(-2.5, 1.5),
		Vector2(1.0, -6.0),
		Vector2(-2.0, -6.0),
	]
)

static var _cockpit_points := PackedVector2Array(
	[
		Vector2(0.0, -12.5),
		Vector2(2.25, -9.0),
		Vector2(0.0, -5.5),
		Vector2(-2.25, -9.0),
	]
)

static var _halo_points := PackedVector2Array(
	[
		Vector2(0.0, -14.0),
		Vector2(3.75, -9.0),
		Vector2(0.0, -4.0),
		Vector2(-3.75, -9.0),
	]
)

var mass: float = 0.001
var collision_radius: float = COLLISION_RADIUS
var input_active: bool = false

var _pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _alive: bool = true
var _fire_cooldown: float = 0.0

var _thrust_node: _GlowLayer
var _ring_node: _RingLayer
var _flicker: float = 0.0
var _pulse_phase: float = 0.0


func _ready():
	_ring_node = _RingLayer.new()
	_ring_node.name = "IndicatorRing"
	add_child(_ring_node)

	_thrust_node = _GlowLayer.new()
	_thrust_node.name = "ThrustFlame"
	add_child(_thrust_node)
	_thrust_node.visible = false

	position = _pos


func init(start_pos: Vector2):
	_pos = start_pos
	position = start_pos


func _physics_process(delta):
	if not _alive:
		return

	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

	if input_active:
		var rotate_left := Input.is_action_pressed("ship_rotate_left")
		var rotate_right := Input.is_action_pressed("ship_rotate_right")
		var thrust_forward := Input.is_action_pressed("ship_thrust_forward")
		var thrust_reverse := Input.is_action_pressed("ship_thrust_reverse")

		if rotate_left and not rotate_right:
			_angle -= ROTATION_SPEED * delta
		elif rotate_right and not rotate_left:
			_angle += ROTATION_SPEED * delta

		var thrust_dir := Vector2.UP.rotated(_angle)

		var thrusting := false
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

	var speed := _vel.length()
	if speed > MAX_SPEED:
		_vel = _vel.normalized() * MAX_SPEED

	_pos += _vel * delta
	position = _pos
	rotation = _angle

	_flicker += delta * 22.0
	_thrust_node._phase = _flicker
	_thrust_node.queue_redraw()

	# Indicator ring pulses only when the ship is not selected (input_active
	# == false), to hint at clickability. When selected, it holds steady.
	_pulse_phase += delta * _PULSE_SPEED
	_ring_node.pulsate = not input_active
	_ring_node.pulse_phase = _pulse_phase
	_ring_node.queue_redraw()

	queue_redraw()


func enforce_sun_barrier(min_dist: float):
	var r := _pos.length()
	if r < min_dist:
		if r < 0.01:
			_pos = Vector2(min_dist, 0.0)
		else:
			_pos = _pos.normalized() * min_dist
		position = _pos
		var radial_dir := _pos.normalized()
		var radial_vel := _vel.dot(radial_dir)
		if radial_vel < 0.0:
			_vel -= radial_dir * radial_vel


func is_alive() -> bool:
	return _alive


func is_dead() -> bool:
	return not _alive


func get_vel() -> Vector2:
	return _vel


func set_vel(v: Vector2):
	_vel = v


func try_fire(target: Node2D) -> Rocket:
	if _fire_cooldown > 0.0 or not _alive:
		return null
	_fire_cooldown = FIRE_COOLDOWN
	var rocket := _ROCKET.new()
	var muzzle_vel := Vector2.UP.rotated(_angle) * FIRE_MUZZLE_SPEED
	rocket.init(_pos, _vel + muzzle_vel, target)
	return rocket


func disable():
	_alive = false
	visible = false


func set_reduced_motion(enabled: bool) -> void:
	_ring_node.reduced_motion = enabled
	_ring_node.queue_redraw()


# ---------------------------------------------------------------------------
# Vector hull rendering (TRON-style neon wireframe)
# ---------------------------------------------------------------------------


func _draw():
	DU.neon_polyline(self, _hull_points, PAL.HULL_GLOW, PAL.HULL_LINE, PAL.HULL_BRIGHT)

	DU.neon_filled_accent(self, _accent_left, PAL.ACCENT, PAL.ACCENT_GLOW, PAL.ACCENT)
	DU.neon_filled_accent(self, _accent_right, PAL.ACCENT, PAL.ACCENT_GLOW, PAL.ACCENT)

	draw_line(Vector2(0.0, -16.0), Vector2(0.0, -10.0), PAL.HULL_LINE, 0.75, true)
	draw_line(Vector2(-5.0, -2.0), Vector2(5.0, -2.0), PAL.HULL_LINE, 0.75, true)
	draw_line(Vector2(-4.0, 3.0), Vector2(4.0, 3.0), PAL.HULL_LINE, 0.75, true)

	draw_colored_polygon(_halo_points, PAL.COCKPIT_GLOW)
	draw_colored_polygon(_cockpit_points, PAL.COCKPIT)


# ---------------------------------------------------------------------------
# Additive layers: segmented indicator ring + thrust flame
# ---------------------------------------------------------------------------


class _GlowLayer:
	extends Node2D
	const _PORTS := [Vector2(-8.0, 11.0), Vector2(8.0, 11.0)]

	var thrusting := false
	var _phase := 0.0
	var _flame_buf_outer := PackedVector2Array()
	var _flame_buf_inner := PackedVector2Array()

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		_flame_buf_outer.resize(4)
		_flame_buf_inner.resize(4)

	func _draw() -> void:
		for port in _PORTS:
			draw_circle(port, 3.5, PAL.ENGINE_PORT)
			draw_circle(port, 1.5, PAL.PORT_CORE)

		if not thrusting:
			return

		for port in _PORTS:
			var length := 22.0 + sin(_phase) * 6.0
			var hf := 2.5
			_flame_buf_outer[0] = port + Vector2(-hf, 0.0)
			_flame_buf_outer[1] = port + Vector2(hf, 0.0)
			_flame_buf_outer[2] = port + Vector2(hf * 0.6, length)
			_flame_buf_outer[3] = port + Vector2(-hf * 0.6, length)
			draw_colored_polygon(_flame_buf_outer, PAL.FLAME_OUTER)
			_flame_buf_inner[0] = port + Vector2(-hf * 0.45, 0.0)
			_flame_buf_inner[1] = port + Vector2(hf * 0.45, 0.0)
			_flame_buf_inner[2] = port + Vector2(hf * 0.20, length * 0.85)
			_flame_buf_inner[3] = port + Vector2(-hf * 0.20, length * 0.85)
			draw_colored_polygon(_flame_buf_inner, PAL.FLAME_INNER)


class _RingLayer:
	extends Node2D
	var pulsate: bool = true
	var pulse_phase: float = 0.0
	var reduced_motion: bool = false

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _draw() -> void:
		var r := 29.0
		# Four arc segments with symmetric gaps (no heading marker; the
		# pointed hull already conveys direction).
		var segments := 4
		var gap := 0.28

		# Pulsation: when not selected the ring's alpha swings between
		# RING_PULSE_MIN and 1.0 of the (already capped) base values.
		var alpha_mult := 1.0
		if pulsate and not reduced_motion:
			alpha_mult = DU.pulsate_factor(pulse_phase, PAL.RING_PULSE_MIN)

		var glow_c := DU.modulate_alpha(PAL.RING_GLOW, alpha_mult)
		var line_c := DU.modulate_alpha(PAL.RING_LINE, alpha_mult)
		var bright_c := DU.modulate_alpha(PAL.RING_BRIGHT, alpha_mult)

		DU.neon_segmented_ring(self, Vector2.ZERO, r, segments, gap, glow_c, line_c, bright_c)
