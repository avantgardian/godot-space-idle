class_name ImpactFX
extends Node

const TEX: GDScript = preload("res://scripts/util/texture_utils.gd")

var _rings: Array[Dictionary] = []


func spawn_ring(color: Color, width: float, segments: int, timer: float) -> void:
	var ring: Line2D = Line2D.new()
	ring.default_color = color
	ring.width = width
	ring.antialiased = true
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segments + 1):
		var a: float = (float(i) / segments) * TAU
		pts.append(Vector2(cos(a), sin(a)))
	ring.points = pts
	add_child(ring)
	_rings.append({"ring": ring, "timer": timer})


func spawn_glow(pos: Vector2, mass: float, contact_radius: float = 1.0) -> void:
	var t: float = clampf(mass * 10.0, 0.2, 1.0)

	var glow_alpha: float = t
	var glow: Sprite2D = Sprite2D.new()
	@warning_ignore("unsafe_method_access")
	glow.texture = TEX.make_circle_texture(
		64,
		func(r: float, _x: int, _y: int) -> Color:
			var alpha: float = (1.0 - r * r) * glow_alpha * 0.8
			return Color(1.0, 0.85, 0.3, alpha)
	)
	glow.centered = true
	glow.position = pos
	glow.modulate = Color(1, 1, 1, 1)
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(glow)
	var duration: float = 0.5 + t * 1.0
	(
		_rings
		. append(
			{
				"ring": glow,
				"timer": duration,
				"initial": duration,
				"base_scale": contact_radius / 32.0,
				"is_glow": true,
			}
		)
	)


func _process(delta: float) -> void:
	for i: int in range(_rings.size() - 1, -1, -1):
		var rd: Dictionary = _rings[i]
		@warning_ignore("unsafe_cast")
		rd.timer = (rd.timer as float) - delta
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var total: float = rd.get("initial", 0.8) as float
		@warning_ignore("unsafe_cast")
		var t: float = (rd.timer as float) / total
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var base: float = rd.get("base_scale", 1.0) as float
		var s: float = base * (1.0 + (1.0 - t) * 3.0)
		@warning_ignore("unsafe_cast", "unsafe_property_access")
		(rd.ring as Node2D).scale = Vector2(s, s)
		if "is_glow" in rd:
			@warning_ignore("unsafe_cast", "unsafe_property_access")
			(rd.ring as Sprite2D).modulate.a = t * t
		else:
			@warning_ignore("unsafe_cast", "unsafe_property_access")
			(rd.ring as Line2D).default_color.a = t * 0.6
		@warning_ignore("unsafe_cast")
		if (rd.timer as float) <= 0.0:
			@warning_ignore("unsafe_cast", "unsafe_method_access")
			(rd.ring as Node).queue_free()
			_rings.remove_at(i)
