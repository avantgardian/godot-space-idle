class_name CameraController
extends Camera2D

@export var min_zoom: float = 0.3
@export var max_zoom: float = 1.3
@export var move_speed: float = 600.0
@export var zoom_step: float = 0.05
@export var zoom_lerp_speed: float = 10.0

var target_zoom: float = 1.0
var shake_intensity: float = 0.0

var _dragging: bool = false
var _drag_prev: Vector2
var _scroll_accum: float = 0.0
var _follow_target: Node2D = null
var _last_frame: int = 0

func _ready():
	zoom = Vector2(1, 1)
	position = Vector2.ZERO

func _process(delta):
	var now := Time.get_ticks_msec()
	var real_delta: float = (now - _last_frame) / 1000.0 if _last_frame > 0 else delta
	_last_frame = now

	var cur_zoom: float = zoom.x
	if abs(cur_zoom - target_zoom) > 0.0001:
		var new_zoom: float = lerp(cur_zoom, target_zoom, zoom_lerp_speed * delta)
		if abs(new_zoom - target_zoom) < 0.001:
			new_zoom = target_zoom
		zoom = Vector2(new_zoom, new_zoom)
	else:
		zoom = Vector2(target_zoom, target_zoom)

	if _follow_target:
		if is_instance_valid(_follow_target) and not _follow_target.is_dead():
			position = position.lerp(_follow_target.position, 3.0 * real_delta)
		else:
			_follow_target = null

	var move := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1
	if move != Vector2.ZERO:
		_follow_target = null
		move = move.normalized() * move_speed * real_delta / zoom.x
		position += move

	if shake_intensity > 0.0:
		shake_intensity = max(shake_intensity - 15.0 * delta, 0.0)
		position += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
	if event is InputEventPanGesture:
		_scroll_accum += event.delta.y
		while _scroll_accum >= 0.3:
			zoom_out()
			_scroll_accum -= 0.3
		while _scroll_accum <= -0.3:
			zoom_in()
			_scroll_accum += 0.3

func follow_node(node: Node2D):
	_follow_target = node
	target_zoom = max_zoom

func unfollow():
	_follow_target = null

func is_following() -> bool:
	return _follow_target != null and is_instance_valid(_follow_target) and not _follow_target.is_dead()

func get_follow_target() -> Node2D:
	return _follow_target

func zoom_in():
	target_zoom = clamp(target_zoom + zoom_step, min_zoom, max_zoom)
	zoom = Vector2(target_zoom, target_zoom)

func zoom_out():
	target_zoom = clamp(target_zoom - zoom_step, min_zoom, max_zoom)
	zoom = Vector2(target_zoom, target_zoom)

func start_drag(screen_pos: Vector2):
	_follow_target = null
	_dragging = true
	_drag_prev = screen_pos

func end_drag():
	_dragging = false

func update_drag(screen_pos: Vector2):
	if not _dragging:
		return
	var delta_vec: Vector2 = screen_pos - _drag_prev
	position -= delta_vec / zoom.x
	_drag_prev = screen_pos

func trigger_shake(intensity: float):
	shake_intensity = min(shake_intensity + intensity, 40.0)

func get_blur_amount() -> float:
	var t := (zoom.x - min_zoom) / (max_zoom - min_zoom)
	return t * t * 5.0
