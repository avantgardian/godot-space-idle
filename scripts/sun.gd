extends Sprite2D

const TEX := preload("res://scripts/texture_utils.gd")

@export var texture_size: int = 256

var sun_time: float = 0.0
var mass: float = 1.0
var _collision_flash: float = 0.0
var _glow_outer: Sprite2D
var _glow_inner: Sprite2D

var _star_core_0 := Color(1.0, 0.95, 0.8)
var _star_core_1 := Color(1.0, 0.7, 0.2)
var _star_core_2 := Color(0.8, 0.3, 0.05)
var _star_glow_tint := Color(1.0, 0.5, 0.1)
var _star_base_modulate := Color(1.0, 1.0, 0.5)
var _star_hot_modulate := Color(1.0, 0.35, 0.05)
var _star_start_mass := 1.0
var _star_mass_span := 2.0

# Surface physics parameters (driven by STAR_TYPES in progression.gd)
var _limb_strength: float = 0.65
var _granulation_scale: float = 1.0
var _corona_falloff: float = 2.2
var _corona_radius_mult: float = 1.6

const _SUN_SHADER := preload("res://shaders/sun_surface.gdshader")

func generate(star_params: Dictionary = {}) -> void:
	if star_params.has("core_0"):      _star_core_0 = star_params.core_0
	if star_params.has("core_1"):      _star_core_1 = star_params.core_1
	if star_params.has("core_2"):      _star_core_2 = star_params.core_2
	if star_params.has("glow_tint"):   _star_glow_tint = star_params.glow_tint
	if star_params.has("base_mod"):    _star_base_modulate = star_params.base_mod
	if star_params.has("hot_mod"):     _star_hot_modulate = star_params.hot_mod
	if star_params.has("start_mass"):  _star_start_mass = star_params.start_mass
	if star_params.has("mass_span"):   _star_mass_span = star_params.mass_span
	if star_params.has("tex_size"):    texture_size = star_params.tex_size
	if star_params.has("limb_strength"):   _limb_strength = star_params.limb_strength
	if star_params.has("granulation_scale"):_granulation_scale = star_params.granulation_scale
	if star_params.has("corona_falloff"): _corona_falloff = star_params.corona_falloff
	if star_params.has("corona_radius_mult"):_corona_radius_mult = star_params.corona_radius_mult
	_generate_sun_texture()
	_apply_sun_shader()
	_generate_sun_glows()

func _generate_sun_texture():
	# The texture is just a flat-white disk mask. All color, granulation,
	# and limb darkening are computed in sun_surface.gdshader.
	# Anti-aliased silhouette via an alpha fade over the outer 5% so the rim
	# stays smooth regardless of the shader's edge_aa.
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
				var alpha := 1.0
				if t > 0.95:
					alpha = 1.0 - (t - 0.95) / 0.05
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	var tex := ImageTexture.create_from_image(image)
	self.texture = tex

func _apply_sun_shader():
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _SUN_SHADER
	shader_mat.set_shader_parameter("time", 0.0)
	shader_mat.set_shader_parameter("u_limb_strength", _limb_strength)
	shader_mat.set_shader_parameter("u_granulation_scale", _granulation_scale)
	shader_mat.set_shader_parameter("u_core_0", TEX.vec3(_star_core_0))
	shader_mat.set_shader_parameter("u_core_1", TEX.vec3(_star_core_1))
	shader_mat.set_shader_parameter("u_core_2", TEX.vec3(_star_core_2))
	material = shader_mat

func _generate_sun_glows():
	var add_mat := func() -> CanvasItemMaterial:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

# Per-type corona. Game-convention glow: visible aura extending past the
	# photosphere, amplified by the bloom pass (#90). Brightness decays
	# gently per corona_falloff so per-type differences read (M compact, O/B
	# extended) without collapsing the aura.
	var glow_tex := func(size_ratio: float, falloff: float) -> Texture2D:
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
					# Bright core fading to soft outer halo. Quadratic base + per-type
					# decay keeps the inner halo bright while extending the outer reach.
					var brightness := (1.0 - t * t) * (1.0 - 0.5 * t)
					brightness *= pow(1.0 - t, falloff * 0.25)
					brightness *= 1.4  # boost so the aura reads at-a-glance
					var alpha := (1.0 - t * t) * 0.85
					image.set_pixel(x, y, Color(_star_glow_tint.r * brightness,
												_star_glow_tint.g * brightness,
												_star_glow_tint.b * brightness, alpha))
		return ImageTexture.create_from_image(image)

	# Bump minimum radius so every type has a visible aura. corona_radius_mult
	# still varies per type (M compact ~1.8, O/B extended ~2.6) but never collapses.
	var outer_radius: float = max(_corona_radius_mult, 2.0)
	_glow_outer = Sprite2D.new()
	_glow_outer.texture = glow_tex.call(outer_radius, _corona_falloff)
	_glow_outer.centered = true
	_glow_outer.name = "GlowOuter"
	_glow_outer.z_index = -2
	_glow_outer.material = add_mat.call()
	add_child(_glow_outer)

	_glow_inner = Sprite2D.new()
	_glow_inner.texture = glow_tex.call(1.4, _corona_falloff)
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
	# No rigid sprite rotation: the visual motion comes from the shader's
	# animated granulation/flicker. A rotating texture underneath a
	# sphere-projected noise field would fight the shader motion, so we
	# keep the sprite axis-aligned.
	rotation = 0.0
	var breathe := sin(sun_time * 0.5) * 0.04 + 1.0
	scale = Vector2(breathe, breathe)

	# Shader owns the photosphere color; modulate stays near-white so the
	# shader's per-channel gradient isn't overridden. A small pulse keeps the
	# "breathing" feel from the original look.
	modulate = Color.WHITE * (sin(sun_time * 1.2) * 0.05 + 0.95)

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
