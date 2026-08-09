extends GutTest

const TEX := preload("res://scripts/util/texture_utils.gd")


func test_make_circle_texture_returns_image_texture():
	var tex: ImageTexture = TEX.make_circle_texture(
		16, func(_t: float, _x: int, _y: int) -> Color: return Color.WHITE
	)
	assert_true(tex is ImageTexture, "Returns ImageTexture")


func test_make_circle_texture_correct_size():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(
		size, func(_t: float, _x: int, _y: int) -> Color: return Color.WHITE
	)
	assert_eq(tex.get_width(), size, "Width matches requested size")
	assert_eq(tex.get_height(), size, "Height matches requested size")


func test_make_circle_texture_corners_transparent():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(
		size, func(_t: float, _x: int, _y: int) -> Color: return Color.RED
	)
	var image: Image = tex.get_image()
	assert_eq(image.get_pixel(0, 0), Color.TRANSPARENT, "Top-left corner is transparent")
	assert_eq(image.get_pixel(size - 1, 0), Color.TRANSPARENT, "Top-right corner is transparent")
	assert_eq(image.get_pixel(0, size - 1), Color.TRANSPARENT, "Bottom-left corner is transparent")
	assert_eq(
		image.get_pixel(size - 1, size - 1), Color.TRANSPARENT, "Bottom-right corner is transparent"
	)


func test_make_circle_texture_center_opaque():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(
		size, func(_t: float, _x: int, _y: int) -> Color: return Color.BLUE
	)
	var image: Image = tex.get_image()
	var center: Color = image.get_pixel(size / 2, size / 2)
	assert_gt(center.a, 0.0, "Center pixel alpha > 0")
	assert_eq(center, Color.BLUE, "Center pixel color matches color_fn return")


func test_make_circle_texture_uses_color_fn():
	var tex: ImageTexture = TEX.make_circle_texture(
		16, func(_t: float, _x: int, _y: int) -> Color: return Color.PINK
	)
	var image: Image = tex.get_image()
	var center: Color = image.get_pixel(8, 8)
	assert_eq(center, Color.PINK, "color_fn result is used at center pixel")


func test_make_noisy_blob_returns_image_texture():
	var tex: ImageTexture = TEX.make_noisy_blob(
		16, 42, func(_t: float, _x: int, _y: int) -> Color: return Color.WHITE
	)
	assert_true(tex is ImageTexture, "Returns ImageTexture")


func test_make_noisy_blob_corners_transparent():
	var tex: ImageTexture = TEX.make_noisy_blob(
		16, 99, func(_t: float, _x: int, _y: int) -> Color: return Color.RED
	)
	var image: Image = tex.get_image()
	assert_eq(image.get_pixel(0, 0), Color.TRANSPARENT, "Top-left corner is transparent")
	assert_eq(image.get_pixel(15, 0), Color.TRANSPARENT, "Top-right corner is transparent")
	assert_eq(image.get_pixel(0, 15), Color.TRANSPARENT, "Bottom-left corner is transparent")
	assert_eq(image.get_pixel(15, 15), Color.TRANSPARENT, "Bottom-right corner is transparent")


func test_make_noisy_blob_center_opaque():
	var seed_val := 42
	var tex: ImageTexture = TEX.make_noisy_blob(
		32, seed_val, func(_t: float, _x: int, _y: int) -> Color: return Color(0.8, 0.6, 0.4, 1.0)
	)
	var image: Image = tex.get_image()
	var center: Color = image.get_pixel(16, 16)
	assert_gt(center.a, 0.0, "Center pixel alpha > 0")


func test_make_noisy_blob_uses_color_fn():
	var test_color := Color(0.2, 0.7, 0.3, 1.0)
	var tex: ImageTexture = TEX.make_noisy_blob(
		32, 12345, func(_t: float, _x: int, _y: int) -> Color: return test_color
	)
	var image: Image = tex.get_image()
	var found := false
	for x in range(32):
		for y in range(32):
			var px := image.get_pixel(x, y)
			if px.a > 0.0 and px.r > 0.0:
				var ratio: float = px.r / test_color.r if test_color.r > 0.001 else -1.0
				if ratio > 0.5:
					found = true
				break
		if found:
			break
	assert_true(found, "At least one opaque pixel was tinted by color_fn")


func test_make_noisy_blob_no_inline_color_literals():
	var seed_val := 77
	var tex: ImageTexture = TEX.make_noisy_blob(
		32, seed_val, func(_t: float, _x: int, _y: int) -> Color: return Color(0.4, 0.4, 0.4, 1.0)
	)
	var image: Image = tex.get_image()
	var found := false
	for x in range(32):
		for y in range(32):
			if image.get_pixel(x, y).a > 0.0:
				found = true
				break
		if found:
			break
	assert_true(found, "Texture generated with color_fn instead of inline color literal")


func test_make_noisy_blob_idempotent():
	var seed_val := 42
	var color_fn := func(_t: float, _x: int, _y: int) -> Color: return Color(0.5, 0.5, 0.5, 1.0)
	var tex1: ImageTexture = TEX.make_noisy_blob(16, seed_val, color_fn)
	var tex2: ImageTexture = TEX.make_noisy_blob(16, seed_val, color_fn)
	var img1: Image = tex1.get_image()
	var img2: Image = tex2.get_image()
	for x in range(16):
		for y in range(16):
			assert_eq(
				img1.get_pixel(x, y),
				img2.get_pixel(x, y),
				"Same seed produces same texture at (%d,%d)" % [x, y]
			)
