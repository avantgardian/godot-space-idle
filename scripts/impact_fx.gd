class_name ImpactFX
extends Node

var _rings: Array[Dictionary] = []

func spawn_ring(color: Color, width: float, segments: int, timer: float):
	var ring := Line2D.new()
	ring.default_color = color
	ring.width = width
	ring.antialiased = true
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var a := (float(i) / segments) * TAU
		pts.append(Vector2(cos(a), sin(a)))
	ring.points = pts
	get_parent().add_child(ring)
	_rings.append({ ring = ring, timer = timer })

func spawn_glow(pos: Vector2, mass: float, contact_radius: float = 1.0):
	var t := clampf(mass * 10.0, 0.2, 1.0)

	var tex_size := 64
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var half := tex_size / 2.0
	var max_r := half - 1.0
	for x in range(tex_size):
		for y in range(tex_size):
			var dx := x - half
			var dy := y - half
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var nt := dist / max_r
				var alpha := (1.0 - nt * nt) * t * 0.8
				image.set_pixel(x, y, Color(1.0, 0.85, 0.3, alpha))

	var glow := Sprite2D.new()
	glow.texture = ImageTexture.create_from_image(image)
	glow.centered = true
	glow.position = pos
	glow.modulate = Color(1, 1, 1, 1)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	get_parent().add_child(glow)
	var duration := 0.5 + t * 1.0
	_rings.append({ ring = glow, timer = duration, initial = duration, base_scale = contact_radius / 32.0, is_glow = true })

func _process(delta):
	for i in range(_rings.size() - 1, -1, -1):
		var rd := _rings[i]
		rd.timer -= delta
		var total: float = rd.get("initial", 0.8)
		var t: float = rd.timer / total
		var base: float = rd.get("base_scale", 1.0)
		var s := base * (1.0 + (1.0 - t) * 3.0)
		rd.ring.scale = Vector2(s, s)
		if "is_glow" in rd:
			rd.ring.modulate.a = t * t
		else:
			rd.ring.default_color.a = t * 0.6
		if rd.timer <= 0.0:
			rd.ring.queue_free()
			_rings.remove_at(i)
