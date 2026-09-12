class_name TextureUtils

static var _disk_mask_cache: Dictionary = {}
static var _white_square: ImageTexture = null


static func make_circle_texture(size: int, color_fn: Callable) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var half: float = size / 2.0
	var max_r: float = half - 1.0
	for x: int in range(size):
		for y: int in range(size):
			var dx: float = x - half
			var dy: float = y - half
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var t: float = dist / max_r
				@warning_ignore("unsafe_method_access")
				var col: Color = color_fn.call(t, x, y) as Color
				image.set_pixel(x, y, col)
	return ImageTexture.create_from_image(image)


static func make_white_square() -> ImageTexture:
	if _white_square:
		return _white_square
	var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	_white_square = ImageTexture.create_from_image(image)
	return _white_square


static func make_disk_mask(size: int, edge_aa_threshold: float = 0.98) -> ImageTexture:
	var key: String = "%d|%.3f" % [size, edge_aa_threshold]
	if _disk_mask_cache.has(key):
		@warning_ignore("unsafe_cast")
		return _disk_mask_cache[key] as ImageTexture
	var radius: float = size / 2.0
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for x: int in range(size):
		for y: int in range(size):
			var dx: float = x - radius
			var dy: float = y - radius
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= radius:
				var t: float = dist / radius
				var alpha: float = 1.0
				if t > edge_aa_threshold:
					alpha = 1.0 - (t - edge_aa_threshold) / (1.0 - edge_aa_threshold)
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	var tex: ImageTexture = ImageTexture.create_from_image(image)
	_disk_mask_cache[key] = tex
	return tex


static func make_noisy_blob(size: int, rng_seed: int, color_fn: Callable) -> ImageTexture:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var max_r: float = size / 2.0 - 1
	for x: int in range(size):
		for y: int in range(size):
			var dx: float = x - cx
			var dy: float = y - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var noise: float = rng.randf_range(0.7, 1.0)
				if dist <= max_r * noise:
					var t: float = dist / max_r
					@warning_ignore("unsafe_method_access")
					var base_color: Color = color_fn.call(t, x, y) as Color
					var bright_factor: float = rng.randf_range(0.6, 1.0)
					var c: Color = Color(
						base_color.r * bright_factor,
						base_color.g * bright_factor,
						base_color.b * bright_factor
					)
					var alpha: float = 1.0
					if dist > max_r * noise * 0.7:
						alpha = 1.0 - (dist - max_r * noise * 0.7) / (max_r * noise * 0.3)
					image.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	return ImageTexture.create_from_image(image)


static func draw_disk_on_image(
	image: Image, cx: float, cy: float, radius: float, color: Color
) -> void:
	var r: int = ceili(radius)
	for dx: int in range(-r, r + 1):
		for dy: int in range(-r, r + 1):
			var dist: float = Vector2(dx, dy).length()
			if dist <= radius:
				var px: int = int(cx) + dx
				var py: int = int(cy) + dy
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					var alpha: float = 1.0
					if dist > radius * 0.7 and radius > 1.0:
						alpha = 1.0 - (dist - radius * 0.7) / (radius * 0.3)
					var final_color: Color = Color(color.r, color.g, color.b, color.a * alpha)
					var existing: Color = image.get_pixel(px, py)
					image.set_pixel(px, py, final_color.blend(existing))
