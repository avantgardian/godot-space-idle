class_name TextureUtils

static var _disk_mask_cache := {}

static func make_circle_texture(size: int, color_fn: Callable) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var half := size / 2.0
	var max_r := half - 1.0
	for x in range(size):
		for y in range(size):
			var dx := x - half
			var dy := y - half
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var t := dist / max_r
				image.set_pixel(x, y, color_fn.call(t, x, y))
	return ImageTexture.create_from_image(image)

static func make_disk_mask(size: int, edge_aa_threshold: float = 0.98) -> ImageTexture:
	var key := "%d|%.3f" % [size, edge_aa_threshold]
	if _disk_mask_cache.has(key):
		return _disk_mask_cache[key]
	var radius := size / 2.0
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x in range(size):
		for y in range(size):
			var dx := x - radius
			var dy := y - radius
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= radius:
				var t := dist / radius
				var alpha: float = 1.0
				if t > edge_aa_threshold:
					alpha = 1.0 - (t - edge_aa_threshold) / (1.0 - edge_aa_threshold)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var tex := ImageTexture.create_from_image(image)
	_disk_mask_cache[key] = tex
	return tex

static func make_noisy_blob(size: int, rng_seed: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx := size / 2.0
	var max_r := size / 2.0 - 1
	for x in range(size):
		for y in range(size):
			var dx := x - cx
			var dy := y - cx
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var noise := rng.randf_range(0.7, 1.0)
				if dist <= max_r * noise:
					var bright := rng.randf_range(0.3, 0.5)
					var c := Color(bright, bright * 0.95, bright * 0.9)
					var alpha := 1.0
					if dist > max_r * noise * 0.7:
						alpha = 1.0 - (dist - max_r * noise * 0.7) / (max_r * noise * 0.3)
					image.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	return ImageTexture.create_from_image(image)

static func draw_disk_on_image(image: Image, cx: float, cy: float, radius: float, color: Color):
	var r := ceili(radius)
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var dist := Vector2(dx, dy).length()
			if dist <= radius:
				var px := int(cx) + dx
				var py := int(cy) + dy
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					var alpha := 1.0
					if dist > radius * 0.7 and radius > 1.0:
						alpha = 1.0 - (dist - radius * 0.7) / (radius * 0.3)
					var final_color := Color(color.r, color.g, color.b, color.a * alpha)
					var existing := image.get_pixel(px, py)
					image.set_pixel(px, py, final_color.blend(existing))

static func vec3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
