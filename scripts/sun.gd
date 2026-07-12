extends Sprite2D

@export var texture_size: int = 256

var sun_time: float = 0.0
var mass: float = 1.0
var _collision_flash: float = 0.0
var _glow_outer: Sprite2D
var _glow_inner: Sprite2D

const _SUN_SHADER := preload("res://shaders/sun_noise.gdshader")

func generate():
	_generate_sun_texture()
	_apply_sun_shader()
	_generate_sun_glows()

func _generate_sun_texture():
	var size := texture_size
	var radius := size / 2.0
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var center := Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center)
			if dist <= radius:
				var t := dist / radius
				var color: Color
				if t < 0.2:
					color = Color(1.0, 0.95, 0.8)
				elif t < 0.6:
					var lt := (t - 0.2) / 0.4
					color = Color(1.0, 0.95, 0.8).lerp(Color(1.0, 0.7, 0.2), lt)
				else:
					var lt := (t - 0.6) / 0.4
					color = Color(1.0, 0.7, 0.2).lerp(Color(0.8, 0.3, 0.05), lt)
				var alpha := 1.0
				if t > 0.85:
					alpha = 1.0 - (t - 0.85) / 0.15
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))

	var tex := ImageTexture.create_from_image(image)
	self.texture = tex

func _apply_sun_shader():
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _SUN_SHADER
	shader_mat.set_shader_parameter("time", 0.0)
	material = shader_mat

func _generate_sun_glows():
	var add_mat := func() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

	var glow_tex := func(size_ratio: float) -> Texture2D:
		var size := int(texture_size * size_ratio)
		var radius := size / 2.0
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		var center := Vector2(radius, radius)
		for x in range(size):
			for y in range(size):
				var dist := Vector2(x, y).distance_to(center)
				if dist <= radius:
					var t := dist / radius
					image.set_pixel(x, y, Color(1.0, 0.5 + 0.5 * (1.0 - t), 0.1, (1.0 - t * t) * 0.6))
		return ImageTexture.create_from_image(image)

	_glow_outer = Sprite2D.new()
	_glow_outer.texture = glow_tex.call(2.0)
	_glow_outer.centered = true
	_glow_outer.name = "GlowOuter"
	_glow_outer.z_index = -2
	_glow_outer.material = add_mat.call()
	add_child(_glow_outer)

	_glow_inner = Sprite2D.new()
	_glow_inner.texture = glow_tex.call(1.25)
	_glow_inner.centered = true
	_glow_inner.name = "GlowInner"
	_glow_inner.z_index = -1
	_glow_inner.material = add_mat.call()
	add_child(_glow_inner)

func flash(intensity: float):
	_collision_flash = max(_collision_flash, intensity)

func _process(delta):
	sun_time += delta
	material.set_shader_parameter("time", sun_time)
	rotation += delta * 0.2
	var breathe := sin(sun_time * 0.5) * 0.04 + 1.0
	scale = Vector2(breathe, breathe)

	var mass_t: float = clamp((mass - 1.0) / 2.0, 0.0, 1.0)
	var temp_color: Color = Color(1.0, 1.0, 0.5).lerp(Color(1.0, 0.35, 0.05), mass_t)
	modulate = temp_color * (sin(sun_time * 1.2) * 0.05 + 0.95)

	var outer_pulse := sin(sun_time * 0.25) * 0.12 + 1.12
	var outer_alpha := sin(sun_time * 0.2 + 0.5) * 0.2 + 0.4
	var inner_pulse := sin(sun_time * 0.35 + 1.2) * 0.06 + 1.06
	var inner_alpha := sin(sun_time * 0.3 + 0.3) * 0.15 + 0.6

	if _collision_flash > 0.0:
		var t: float = _collision_flash / 0.6
		var flash_t: float = t * t
		modulate = modulate.lerp(Color.WHITE, flash_t * 0.7)
		scale = Vector2(breathe, breathe) * (1.0 + flash_t * 0.15)
		var pulse := 1.0 + flash_t * 0.4
		_glow_outer.scale = Vector2(outer_pulse, outer_pulse) * pulse
		_glow_outer.modulate = Color(1, 1, 1, outer_alpha + flash_t * 0.5)
		_glow_inner.scale = Vector2(inner_pulse, inner_pulse) * pulse
		_glow_inner.modulate = Color(1, 1, 1, inner_alpha + flash_t * 0.5)
		_collision_flash -= delta
	else:
		_glow_outer.scale = Vector2(outer_pulse, outer_pulse)
		_glow_outer.modulate = Color(1, 1, 1, outer_alpha)
		_glow_inner.scale = Vector2(inner_pulse, inner_pulse)
		_glow_inner.modulate = Color(1, 1, 1, inner_alpha)
