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
const PAL := preload("res://scripts/tron_palette.gd")
const DU  := preload("res://scripts/draw_utils.gd")

var mass: float = 0.001
var collision_radius: float = COLLISION_RADIUS
var input_active: bool = false

var _pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO
var _angle: float = 0.0
var _alive: bool = true

var _thrust_node: Node2D
var _ring_node: Node2D
var _flicker: float = 0.0
var _pulse_phase: float = 0.0
const _PULSE_SPEED: float = PAL.RING_PULSE_SPEED  # rad/s pulsation when not selected

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

func _process(delta):
	if not _alive:
		return

	if input_active:
		var rotate_left := Input.is_key_pressed(KEY_LEFT)
		var rotate_right := Input.is_key_pressed(KEY_RIGHT)
		var thrust_forward := Input.is_key_pressed(KEY_UP)
		var thrust_reverse := Input.is_key_pressed(KEY_DOWN)

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
		if _thrust_node is _GlowLayer:
			(_thrust_node as _GlowLayer).thrusting = thrusting
	else:
		_thrust_node.visible = false
		if _thrust_node is _GlowLayer:
			(_thrust_node as _GlowLayer).thrusting = false

	_vel *= max(1.0 - DAMPING * delta, 0.0)

	var speed := _vel.length()
	if speed > MAX_SPEED:
		_vel = _vel.normalized() * MAX_SPEED

	_pos += _vel * delta
	position = _pos
	rotation = _angle

	_flicker += delta * 22.0
	if _thrust_node is _GlowLayer:
		(_thrust_node as _GlowLayer)._phase = _flicker
		_thrust_node.queue_redraw()

	# Indicator ring pulses only when the ship is not selected (input_active
	# == false), to hint at clickability. When selected, it holds steady.
	_pulse_phase += delta * _PULSE_SPEED
	if _ring_node is _RingLayer:
		(_ring_node as _RingLayer).pulsate = not input_active
		(_ring_node as _RingLayer).pulse_phase = _pulse_phase
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

func disable():
	_alive = false
	visible = false

# ---------------------------------------------------------------------------
# Vector hull rendering (TRON-style neon wireframe)
# ---------------------------------------------------------------------------

func _hull_points() -> PackedVector2Array:
	# Pointed nose up, swept-back wings, twin engine pods, notched tail.
	# Closed polyline (last point == first) so draw_polyline closes cleanly.
	return PackedVector2Array([
		Vector2(0.0,   -18.0),  # nose tip
		Vector2(-5.0,   -8.0),  # shoulder left
		Vector2(-13.0,   6.0),  # outer wing tip left
		Vector2(-9.0,    7.0),  # wing root left
		Vector2(-9.0,   11.0),  # engine outer left
		Vector2(-5.0,  11.0),  # engine inner left
		Vector2(-5.0,   7.0),  # notch back left
		Vector2(0.0,    9.0),  # tail center
		Vector2(5.0,    7.0),  # notch back right
		Vector2(5.0,  11.0),  # engine inner right
		Vector2(9.0,   11.0),  # engine outer right
		Vector2(9.0,    7.0),  # wing root right
		Vector2(13.0,   6.0),  # outer wing tip right
		Vector2(5.0,   -8.0),  # shoulder right
		Vector2(0.0,  -18.0),  # close
	])

func _accent_quad(side: int) -> PackedVector2Array:
	# Short diagonal stripe hugging the inner wing leading edge.
	# side = -1 left / +1 right
	var s := float(side)
	return PackedVector2Array([
		Vector2(-2.0 * s, -6.0),
		Vector2(-4.5 * s,  1.5),
		Vector2(-2.5 * s,  1.5),
		Vector2( 1.0 * s, -6.0),
		Vector2(-2.0 * s, -6.0),  # close
	])

func _cockpit_poly() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2( 0.0,   -12.5),
		Vector2( 2.25, -9.0),
		Vector2( 0.0,   -5.5),
		Vector2(-2.25, -9.0),
	])

func _draw():
	# Hull outline (3-stroke neon triple-stack: glow -> line -> bright core).
	DU.neon_polyline(self, _hull_points(), PAL.HULL_GLOW, PAL.HULL_LINE, PAL.HULL_BRIGHT)

	# Orange wing accent stripes (filled accent quad + glowing outline).
	for side in [-1, 1]:
		DU.neon_filled_accent(self, _accent_quad(side), PAL.ACCENT, PAL.ACCENT_GLOW, PAL.ACCENT)

	# Inner brace lines (recognizer-style cross-bracing).
	draw_line(Vector2(0.0, -16.0), Vector2(0.0, -10.0), PAL.HULL_LINE, 0.75, true)
	draw_line(Vector2(-5.0, -2.0), Vector2(5.0, -2.0), PAL.HULL_LINE, 0.75, true)
	draw_line(Vector2(-4.0,  3.0), Vector2(4.0,  3.0), PAL.HULL_LINE, 0.75, true)

	# Cockpit core: soft glow halo (larger, dim) + bright filled diamond.
	var halo := PackedVector2Array([
		Vector2( 0.0,   -14.0),
		Vector2( 3.75, -9.0),
		Vector2( 0.0,   -4.0),
		Vector2(-3.75, -9.0),
	])
	draw_colored_polygon(halo, PAL.COCKPIT_GLOW)
	draw_colored_polygon(_cockpit_poly(), PAL.COCKPIT)

# ---------------------------------------------------------------------------
# Additive layers: segmented indicator ring + thrust flame
# ---------------------------------------------------------------------------

class _GlowLayer extends Node2D:
	var thrusting := false
	var _phase := 0.0

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _draw() -> void:
		# Twin engine port glows (always-on small halos).
		for port in [Vector2(-8.0, 11.0), Vector2(8.0, 11.0)]:
			draw_circle(port, 3.5, TronPalette.ENGINE_PORT)
			draw_circle(port, 1.5, TronPalette.PORT_CORE)

		if not thrusting:
			return

		# Dual twin-jet exhausts (TRON jet-blue, additive).
		for port in [Vector2(-8.0, 11.0), Vector2(8.0, 11.0)]:
			var length := 22.0 + sin(_phase) * 6.0
			var hf := 2.5
			var outer := PackedVector2Array([
				port + Vector2(-hf,       0.0),
				port + Vector2( hf,       0.0),
				port + Vector2( hf * 0.6, length),
				port + Vector2(-hf * 0.6, length),
			])
			draw_colored_polygon(outer, TronPalette.FLAME_OUTER)
			var inner := PackedVector2Array([
				port + Vector2(-hf * 0.45, 0.0),
				port + Vector2( hf * 0.45, 0.0),
				port + Vector2( hf * 0.20, length * 0.85),
				port + Vector2(-hf * 0.20, length * 0.85),
			])
			draw_colored_polygon(inner, TronPalette.FLAME_INNER)

class _RingLayer extends Node2D:
	var pulsate: bool = true
	var pulse_phase: float = 0.0

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
		if pulsate:
			alpha_mult = DrawUtils.pulsate_factor(pulse_phase, TronPalette.RING_PULSE_MIN)

		var glow_c   := DrawUtils.modulate_alpha(TronPalette.RING_GLOW,   alpha_mult)
		var line_c   := DrawUtils.modulate_alpha(TronPalette.RING_LINE,   alpha_mult)
		var bright_c := DrawUtils.modulate_alpha(TronPalette.RING_BRIGHT, alpha_mult)

		DrawUtils.neon_segmented_ring(self, Vector2.ZERO, r, segments, gap, glow_c, line_c, bright_c)