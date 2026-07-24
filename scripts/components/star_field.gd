extends Node2D

const TEX := preload("res://scripts/util/texture_utils.gd")

const LAYERS := [
	{ count=500, min_r=0.2, max_r=0.5, min_b=0.08, max_b=0.25, motion_scale=0.003 },
	{ count=400, min_r=0.3, max_r=0.7, min_b=0.12, max_b=0.35, motion_scale=0.008 },
	{ count=300, min_r=0.4, max_r=1.0, min_b=0.2, max_b=0.45, motion_scale=0.018 },
	{ count=200, min_r=0.5, max_r=1.5, min_b=0.3, max_b=0.55, motion_scale=0.04 },
	{ count=120, min_r=0.8, max_r=2.0, min_b=0.4, max_b=0.75, motion_scale=0.08 },
	{ count=60,  min_r=1.5, max_r=3.0, min_b=0.6, max_b=1.0,  motion_scale=0.18 },
]

const _STAR_SHADER := preload("res://shaders/world/star_blur.gdshader")

var _sprites: Array[Sprite2D]
var _motion_scales: Array[float]

func generate(seed_val: int, min_zoom: float):
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var tile_scale = 2.0 / min_zoom
	var screen_size := get_viewport_rect().size

	for cfg in LAYERS:
		var image := Image.create(int(screen_size.x), int(screen_size.y), false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)

		for _j in range(cfg.count):
			var x := rng.randf_range(0.0, screen_size.x)
			var y := rng.randf_range(0.0, screen_size.y)
			var radius := rng.randf_range(cfg.min_r, cfg.max_r)
			var brightness := rng.randf_range(cfg.min_b, cfg.max_b)
			var color := Color(brightness, brightness, brightness, 1.0)
			_draw_star_wrapped(image, x, y, radius, color)

		var texture := ImageTexture.create_from_image(image)

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2(tile_scale, tile_scale)

		var mat := ShaderMaterial.new()
		mat.shader = _STAR_SHADER
		mat.set_shader_parameter("tiles", tile_scale)
		mat.set_shader_parameter("blur_amount", 0.0)
		sprite.material = mat

		_sprites.append(sprite)
		_motion_scales.append(cfg.motion_scale)
		add_child(sprite)

func update_parallax(camera_position: Vector2, camera_zoom: float):
	var screen_size := get_viewport_rect().size
	var world_half = screen_size * 0.5 / camera_zoom

	for i in _sprites.size():
		var sprite := _sprites[i]
		var ms := _motion_scales[i]
		var origin = -camera_position * ms
		sprite.position = Vector2(
			origin.x + _align_floor(camera_position.x - world_half.x - origin.x, screen_size.x),
			origin.y + _align_floor(camera_position.y - world_half.y - origin.y, screen_size.y)
		)

func set_blur(amount: float):
	for sprite in _sprites:
		var mat := sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("blur_amount", amount)

func _align_floor(offset: float, period: float) -> float:
	return floor(offset / period) * period

func _draw_star_wrapped(image: Image, x: float, y: float, radius: float, color: Color):
	var w := image.get_width()
	var h := image.get_height()
	_draw_star_on_image(image, x, y, radius, color)
	if x - radius < 0:
		_draw_star_on_image(image, x + w, y, radius, color)
		if y - radius < 0:
			_draw_star_on_image(image, x + w, y + h, radius, color)
		if y + radius >= h:
			_draw_star_on_image(image, x + w, y - h, radius, color)
	if x + radius >= w:
		_draw_star_on_image(image, x - w, y, radius, color)
		if y - radius < 0:
			_draw_star_on_image(image, x - w, y + h, radius, color)
		if y + radius >= h:
			_draw_star_on_image(image, x - w, y - h, radius, color)
	if y - radius < 0:
		_draw_star_on_image(image, x, y + h, radius, color)
	if y + radius >= h:
		_draw_star_on_image(image, x, y - h, radius, color)

func _draw_star_on_image(image: Image, cx: float, cy: float, radius: float, color: Color):
	TEX.draw_disk_on_image(image, cx, cy, radius, color)
