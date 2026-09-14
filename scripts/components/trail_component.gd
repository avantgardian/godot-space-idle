class_name TrailComponent
extends Node2D

const DOWNSAMPLE_THRESHOLD: int = 8000
const RECORD_INTERVAL: int = 6

var _line: Line2D
var _ring: PackedVector2Array
var _head: int = 0
var _filled: int = 0
var _max_points: int = 1200
var _tick: int = 0
var _fading: bool = false
var _stride: int = 1
var _vis_buffer: PackedVector2Array = PackedVector2Array()
var _vis_dirty: bool = false


func setup(color0: Color, color1: Color, width: float, max_points: int) -> void:
	_max_points = max_points
	_ring.resize(_max_points)
	_ring.fill(Vector2.ZERO)
	if _max_points > DOWNSAMPLE_THRESHOLD:
		_stride = ceili(float(_max_points) / DOWNSAMPLE_THRESHOLD)
	else:
		_stride = 1
	_vis_buffer = PackedVector2Array()
	_vis_dirty = false
	_line = Line2D.new()
	_line.top_level = true
	_line.width = width
	_line.antialiased = true
	_line.z_index = -30
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_line.material = mat
	var grad: Gradient = Gradient.new()
	grad.set_color(0, color0)
	grad.set_color(1, color1)
	_line.gradient = grad
	add_child(_line)


func record(pos: Vector2) -> void:
	if _fading:
		return
	_tick += 1
	if _tick % RECORD_INTERVAL != 0:
		return
	_ring[_head] = pos
	_head = (_head + 1) % _max_points
	_filled = mini(_filled + 1, _max_points)
	_vis_dirty = true
	if _line and _filled >= 2:
		_update_line()


func _update_line() -> void:
	if not _vis_dirty:
		return
	_vis_dirty = false
	var count: int = _filled
	var start: int = (_head - count + _max_points) % _max_points
	var vis_count: int = ceili(float(count) / _stride)
	if _vis_buffer.size() != vis_count:
		_vis_buffer.resize(vis_count)
	for i: int in range(vis_count):
		_vis_buffer[i] = _ring[(start + i * _stride) % _max_points]
	_line.points = _vis_buffer


func _visible_slice() -> PackedVector2Array:
	var count: int = _filled
	var start: int = (_head - count + _max_points) % _max_points
	var vis_count: int = ceili(float(count) / _stride)
	var result: PackedVector2Array = PackedVector2Array()
	result.resize(vis_count)
	for i: int in range(vis_count):
		result[i] = _ring[(start + i * _stride) % _max_points]
	return result


func clear() -> void:
	_ring.fill(Vector2.ZERO)
	_head = 0
	_filled = 0
	_tick = 0
	_vis_dirty = false
	_vis_buffer = PackedVector2Array()
	if _line:
		_line.points = PackedVector2Array()


func fade_out(fade_seconds: float = 4.0) -> void:
	if _fading or not _line:
		return
	_fading = true
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		reparent(scene_root)
	var tw: Tween = create_tween()
	tw.tween_property(_line, "self_modulate:a", 0.0, fade_seconds)
	tw.tween_callback(queue_free)
