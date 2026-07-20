class_name TextureUtils

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

static func vec3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
