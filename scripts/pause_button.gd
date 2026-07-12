extends Button

var _paused := false
var _overlay: ColorRect

func _ready():
	name = "PauseButton"
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -96.0
	offset_top = -46.0
	offset_right = -16.0
	offset_bottom = -16.0
	text = "Pause"

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.5)
	sb.border_color = Color(0.5, 0.6, 0.8, 0.9)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	add_theme_stylebox_override("normal", sb)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.15, 0.2, 0.35, 0.6)
	sb_hover.border_color = Color(0.7, 0.8, 1.0, 1.0)
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left = 4
	sb_hover.corner_radius_top_right = 4
	sb_hover.corner_radius_bottom_right = 4
	sb_hover.corner_radius_bottom_left = 4
	sb_hover.content_margin_left = 12
	sb_hover.content_margin_right = 12
	sb_hover.content_margin_top = 4
	sb_hover.content_margin_bottom = 4
	add_theme_stylebox_override("hover", sb_hover)

	add_theme_color_override("font_color", Color(0.8, 0.85, 1.0, 1.0))
	add_theme_font_size_override("font_size", 14)

	_overlay = ColorRect.new()
	_overlay.name = "PauseOverlay"
	_overlay.anchor_left = 0.0
	_overlay.anchor_top = 0.0
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.3)
	_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	_overlay.hide()
	get_parent().call_deferred("add_child", _overlay)

	pressed.connect(_toggle)

func _toggle():
	_paused = not _paused
	Engine.time_scale = 0.0 if _paused else 1.0
	text = "Play" if _paused else "Pause"
	_overlay.visible = _paused
