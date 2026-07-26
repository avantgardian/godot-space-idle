extends GutTest

const TEX := preload("res://scripts/util/texture_utils.gd")

func test_make_circle_texture_returns_image_texture():
	var tex: ImageTexture = TEX.make_circle_texture(16, func(_t: float, _x: int, _y: int) -> Color: return Color.WHITE)
	assert_true(tex is ImageTexture, "Returns ImageTexture")

func test_make_circle_texture_correct_size():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(size, func(_t: float, _x: int, _y: int) -> Color: return Color.WHITE)
	assert_eq(tex.get_width(), size, "Width matches requested size")
	assert_eq(tex.get_height(), size, "Height matches requested size")

func test_make_circle_texture_corners_transparent():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(size, func(_t: float, _x: int, _y: int) -> Color: return Color.RED)
	var image: Image = tex.get_image()
	assert_eq(image.get_pixel(0, 0), Color.TRANSPARENT, "Top-left corner is transparent")
	assert_eq(image.get_pixel(size - 1, 0), Color.TRANSPARENT, "Top-right corner is transparent")
	assert_eq(image.get_pixel(0, size - 1), Color.TRANSPARENT, "Bottom-left corner is transparent")
	assert_eq(image.get_pixel(size - 1, size - 1), Color.TRANSPARENT, "Bottom-right corner is transparent")

func test_make_circle_texture_center_opaque():
	var size: int = 32
	var tex: ImageTexture = TEX.make_circle_texture(size, func(_t: float, _x: int, _y: int) -> Color: return Color.BLUE)
	var image: Image = tex.get_image()
	var center: Color = image.get_pixel(size / 2, size / 2)
	assert_gt(center.a, 0.0, "Center pixel alpha > 0")
	assert_eq(center, Color.BLUE, "Center pixel color matches color_fn return")

func test_make_circle_texture_uses_color_fn():
	var tex: ImageTexture = TEX.make_circle_texture(16, func(_t: float, _x: int, _y: int) -> Color:
		return Color.PINK
	)
	var image: Image = tex.get_image()
	var center: Color = image.get_pixel(8, 8)
	assert_eq(center, Color.PINK, "color_fn result is used at center pixel")
