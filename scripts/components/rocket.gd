class_name Rocket
extends Node2D

signal resolved(reason: Resolution)

enum Resolution {
	HIT_TARGET,
	DEPLETED,
	LOST,
}

const SPEED: float = 200.0
const HOMING_STRENGTH: float = 125.0
const LIFETIME: float = 10.0
const COLLISION_RADIUS: float = 5.0
const SPAWN_PROTECTION_TIME: float = 0.3

const PAL := preload("res://scripts/util/tron_palette.gd")
const DU := preload("res://scripts/util/draw_utils.gd")
const _TRAIL := preload("res://scripts/components/trail_component.gd")

var collision_radius: float = COLLISION_RADIUS
var mass: float = 0.0

var _pos: Vector2
var _vel: Vector2
var _alive: bool = true
var _lifetime: float = LIFETIME
var _spawn_protection: float = SPAWN_PROTECTION_TIME
var _target: Node2D = null
var _trail_component: Node
var _resolved: bool = false


func init(start_pos: Vector2, start_vel: Vector2, target: Node2D) -> void:
	_pos = start_pos
	_vel = start_vel
	_target = target
	position = _pos


func is_alive() -> bool:
	return _alive


func disable(reason: Resolution = Resolution.LOST) -> void:
	if _resolved:
		return
	_resolved = true
	if _trail_component:
		_trail_component.fade_out()
	_alive = false
	visible = false
	resolved.emit(reason)


func get_vel() -> Vector2:
	return _vel


func set_vel(v: Vector2) -> void:
	_vel = v


func has_spawn_protection() -> bool:
	return _spawn_protection > 0.0


func _ready() -> void:
	_trail_component = _TRAIL.new()
	var accent := PAL.ACCENT
	_trail_component.setup(
		Color(accent.r, accent.g, accent.b, 0.0), Color(accent.r, accent.g, accent.b, 0.7), 1.5, 200
	)
	add_child(_trail_component)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	_lifetime -= delta
	_spawn_protection -= delta

	if _lifetime <= 0.0:
		disable(Resolution.DEPLETED)
		return

	if _target and is_instance_valid(_target):
		var to_target: Vector2 = _target.position - _pos
		var dist: float = to_target.length()
		if dist > 0.01:
			var desired: Vector2 = to_target.normalized() * SPEED
			var steer: Vector2 = desired - _vel
			steer = steer.limit_length(HOMING_STRENGTH * delta)
			_vel += steer

	var speed: float = _vel.length()
	if speed > SPEED:
		_vel = _vel.normalized() * SPEED

	_pos += _vel * delta
	position = _pos

	if _vel.length() > 1.0:
		rotation = _vel.angle() + PI / 2.0

	if _trail_component:
		_trail_component.record(position)

	queue_redraw()


func _draw() -> void:
	if not _alive:
		return

	var nose := Vector2(0.0, -6.0)
	var left := Vector2(-3.0, 4.0)
	var right := Vector2(3.0, 4.0)
	var tail_left := Vector2(-1.5, 0.0)
	var tail_right := Vector2(1.5, 0.0)
	var points := PackedVector2Array([nose, left, tail_left, tail_right, right, nose])

	DU.neon_polyline(self, points, PAL.ACCENT_GLOW, PAL.ACCENT, PAL.HULL_BRIGHT)
