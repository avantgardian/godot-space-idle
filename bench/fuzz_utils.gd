extends RefCounted

## Fuzz input mutation harness (#344) — random InputEvent generation
## for gameplay_smoke --fuzz. Deterministic via global seed(seed_val)
## before the frame loop; route via get_root().push_input + direct
## _unhandled_input to exercise both viewport and controller paths.

const VP_W: float = 1920.0
const VP_H: float = 1080.0
const VALID_MOUSE_BUTTONS: Array[int] = [
	MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN
]
const VALID_KEYS: Array[int] = [KEY_L, KEY_G, KEY_H, KEY_ESCAPE, KEY_SPACE]


static func inject_fuzz(tree: SceneTree, inst: Node, frame: int, seed_val: int) -> void:
	var event: InputEvent = _make_random_event()
	# Log every 25th frame for determinism proof without spamming.
	if frame % 25 == 0:
		print(
			(
				"[fuzz] frame=%d seed=%d event=%s pos=%s"
				% [frame, seed_val, _event_label(event), _event_pos(event)]
			)
		)
	var viewport: Viewport = tree.get_root()
	@warning_ignore("unsafe_method_access")
	viewport.push_input(event)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(event)
	# 15% chance of a second event same frame to hit combos
	# (drag during zoom, rapid pause toggle, click+key).
	if randf() < 0.15:
		var extra: InputEvent = _make_random_event()
		@warning_ignore("unsafe_method_access")
		viewport.push_input(extra)
		if inst.has_method("_unhandled_input"):
			@warning_ignore("unsafe_method_access")
			inst._unhandled_input(extra)


static func _make_random_event() -> InputEvent:
	var roll: int = randi_range(0, 2)
	match roll:
		0:
			return _random_button()
		1:
			return _random_motion()
		_:
			return _random_key()
	return _random_button()


static func _random_button() -> InputEventMouseButton:
	var btn: InputEventMouseButton = InputEventMouseButton.new()
	var idx: int = randi_range(0, VALID_MOUSE_BUTTONS.size() - 1)
	var chosen: int = VALID_MOUSE_BUTTONS[idx]
	btn.button_index = chosen as MouseButton
	# Wheel events are press-only; clicks randomize press.
	if chosen == MOUSE_BUTTON_WHEEL_UP or chosen == MOUSE_BUTTON_WHEEL_DOWN:
		btn.pressed = true
	else:
		btn.pressed = randi_range(0, 1) == 1
	btn.position = Vector2(randf_range(0.0, VP_W), randf_range(0.0, VP_H))
	return btn


static func _random_motion() -> InputEventMouseMotion:
	var mm: InputEventMouseMotion = InputEventMouseMotion.new()
	mm.position = Vector2(randf_range(0.0, VP_W), randf_range(0.0, VP_H))
	mm.relative = Vector2(randf_range(-120.0, 120.0), randf_range(-120.0, 120.0))
	mm.velocity = mm.relative * 60.0
	return mm


static func _random_key() -> InputEventKey:
	var k: InputEventKey = InputEventKey.new()
	var idx: int = randi_range(0, VALID_KEYS.size() - 1)
	k.keycode = VALID_KEYS[idx] as Key
	k.pressed = randi_range(0, 1) == 1
	k.echo = false
	return k


static func _event_label(ev: InputEvent) -> String:
	if ev is InputEventMouseButton:
		@warning_ignore("unsafe_cast")
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		@warning_ignore("unsafe_property_access")
		return "MouseButton btn=%d pressed=%s" % [mb.button_index, str(mb.pressed)]
	if ev is InputEventMouseMotion:
		return "MouseMotion"
	if ev is InputEventKey:
		@warning_ignore("unsafe_cast")
		var kk: InputEventKey = ev as InputEventKey
		@warning_ignore("unsafe_property_access")
		return "Key code=%d pressed=%s" % [kk.keycode, str(kk.pressed)]
	return "Unknown"


static func _event_pos(ev: InputEvent) -> String:
	if ev is InputEventMouseButton:
		@warning_ignore("unsafe_cast")
		var mb2: InputEventMouseButton = ev as InputEventMouseButton
		@warning_ignore("unsafe_property_access")
		return "(%.0f,%.0f)" % [mb2.position.x, mb2.position.y]
	if ev is InputEventMouseMotion:
		@warning_ignore("unsafe_cast")
		var mm2: InputEventMouseMotion = ev as InputEventMouseMotion
		@warning_ignore("unsafe_property_access")
		return (
			"(%.0f,%.0f) rel(%.0f,%.0f)"
			% [mm2.position.x, mm2.position.y, mm2.relative.x, mm2.relative.y]
		)
	return "-"
