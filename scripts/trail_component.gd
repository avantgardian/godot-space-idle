class_name TrailComponent
extends Node2D

var _line: Line2D
var _trail: PackedVector2Array = []
var _tick: int = 0
var _max_points: int = 1200
var _fading: bool = false

func setup(color0: Color, color1: Color, width: float, max_points: int):
	_max_points = max_points
	_line = Line2D.new()
	_line.top_level = true
	_line.width = width
	_line.antialiased = true
	_line.z_index = -1
	var grad := Gradient.new()
	grad.set_color(0, color0)
	grad.set_color(1, color1)
	_line.gradient = grad
	add_child(_line)

func record(pos: Vector2):
	if _fading:
		return
	_tick += 1
	if _tick % 2 == 0:
		_trail.append(pos)
		if _trail.size() > _max_points:
			_trail.remove_at(0)
	if _line and _trail.size() >= 2:
		_line.points = _trail

func clear():
	_trail.clear()
	_tick = 0
	if _line:
		_line.points = PackedVector2Array()

func fade_out(fade_seconds: float = 4.0):
	if _fading or not _line:
		return
	_fading = true
	var scene_root := get_tree().current_scene
	if scene_root:
		reparent(scene_root)
	var tw := create_tween()
	tw.tween_property(_line, "self_modulate:a", 0.0, fade_seconds)
	tw.tween_callback(queue_free)
