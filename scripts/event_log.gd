class_name EventLog
extends Node

const DURATION := 60.0
const MAX_ENTRIES := 30

var _entries: Array[Dictionary] = []
var _container: VBoxContainer

func _ready():
	setup()

func setup():
	var panel := Panel.new()
	panel.name = "EventLogPanel"
	panel.position = Vector2(16, get_viewport().get_visible_rect().size.y - 155)
	panel.size = Vector2(300, 135)
	panel.clip_contents = true

	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.04, 0.1, 0.88)
	psb.border_color = Color(0.35, 0.45, 0.65, 0.6)
	psb.border_width_left = 1
	psb.border_width_top = 1
	psb.border_width_right = 1
	psb.border_width_bottom = 1
	psb.corner_radius_top_left = 4
	psb.corner_radius_top_right = 4
	psb.corner_radius_bottom_right = 4
	psb.corner_radius_bottom_left = 4
	psb.content_margin_left = 8
	psb.content_margin_right = 8
	psb.content_margin_top = 6
	psb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	_container = VBoxContainer.new()
	_container.name = "EventLog"
	_container.position = Vector2(10, 8)
	_container.size = Vector2(280, 119)
	_container.add_theme_constant_override("separation", 2)
	panel.add_child(_container)

func log_message(msg: String):
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 1.0))
	_container.add_child(lbl)
	_container.move_child(lbl, 0)
	_entries.append({ label = lbl, age = 0.0 })
	while _entries.size() > MAX_ENTRIES:
		var oldest := _entries[0]
		_entries.remove_at(0)
		oldest.label.queue_free()

func _process(delta):
	for i in range(_entries.size() - 1, -1, -1):
		var entry := _entries[i]
		entry.age += delta
		var t: float = entry.age / DURATION
		if t >= 1.0:
			entry.label.queue_free()
			_entries.remove_at(i)
		else:
			entry.label.modulate.a = 1.0 - ease(t, 0.5)
