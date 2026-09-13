extends Sprite2D

const TEX: GDScript = preload("res://scripts/util/texture_utils.gd")
const _SUN_SHADER: Shader = preload("res://shaders/world/sun_surface.gdshader")

@export var texture_size: int = 256

var sun_time: float = 0.0
var mass: float = 1.0
var _collision_flash: float = 0.0
var _glow_outer: Sprite2D
var _glow_inner: Sprite2D
var _shader_mat: ShaderMaterial

var _star_core_0: Color = Color(1.0, 0.95, 0.8)
var _star_core_1: Color = Color(1.0, 0.7, 0.2)
var _star_core_2: Color = Color(0.8, 0.3, 0.05)
var _star_glow_tint: Color = Color(1.0, 0.5, 0.1)
var _star_base_modulate: Color = Color(1.0, 1.0, 0.5)
var _star_hot_modulate: Color = Color(1.0, 0.35, 0.05)
var _star_start_mass: float = 1.0
var _star_mass_span: float = 2.0

# Surface physics parameters (driven by STAR_TYPES in progression.gd)
var _limb_strength: float = 0.65
var _granulation_scale: float = 1.0
var _corona_falloff: float = 2.2
var _corona_radius_mult: float = 1.6


func generate(star_params: Dictionary = {}) -> void:
	if star_params.has("core_0"):
		@warning_ignore("unsafe_cast")
		_star_core_0 = star_params.core_0 as Color
	if star_params.has("core_1"):
		@warning_ignore("unsafe_cast")
		_star_core_1 = star_params.core_1 as Color
	if star_params.has("core_2"):
		@warning_ignore("unsafe_cast")
		_star_core_2 = star_params.core_2 as Color
	if star_params.has("glow_tint"):
		@warning_ignore("unsafe_cast")
		_star_glow_tint = star_params.glow_tint as Color
	if star_params.has("base_mod"):
		@warning_ignore("unsafe_cast")
		_star_base_modulate = star_params.base_mod as Color
	if star_params.has("hot_mod"):
		@warning_ignore("unsafe_cast")
		_star_hot_modulate = star_params.hot_mod as Color
	if star_params.has("start_mass"):
		@warning_ignore("unsafe_cast")
		_star_start_mass = star_params.start_mass as float
	if star_params.has("mass_span"):
		@warning_ignore("unsafe_cast")
		_star_mass_span = star_params.mass_span as float
	if star_params.has("tex_size"):
		@warning_ignore("unsafe_cast")
		texture_size = star_params.tex_size as int
	if star_params.has("limb_strength"):
		@warning_ignore("unsafe_cast")
		_limb_strength = star_params.limb_strength as float
	if star_params.has("granulation_scale"):
		@warning_ignore("unsafe_cast")
		_granulation_scale = star_params.granulation_scale as float
	if star_params.has("corona_falloff"):
		@warning_ignore("unsafe_cast")
		_corona_falloff = star_params.corona_falloff as float
	if star_params.has("corona_radius_mult"):
		@warning_ignore("unsafe_cast")
		_corona_radius_mult = star_params.corona_radius_mult as float
	_generate_sun_texture()
	_apply_sun_shader()
	_generate_sun_glows()
	rotation = 0.0


func _generate_sun_texture() -> void:
	@warning_ignore("unsafe_method_access")
	self.texture = TEX.make_disk_mask(texture_size, 0.95)


func _apply_sun_shader() -> void:
	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	shader_mat.shader = _SUN_SHADER
	shader_mat.set_shader_parameter("u_time", 0.0)
	shader_mat.set_shader_parameter("u_limb_strength", _limb_strength)
	shader_mat.set_shader_parameter("u_granulation_scale", _granulation_scale)
	shader_mat.set_shader_parameter("u_core_0", _star_core_0)
	shader_mat.set_shader_parameter("u_core_1", _star_core_1)
	shader_mat.set_shader_parameter("u_core_2", _star_core_2)
	material = shader_mat
	_shader_mat = shader_mat


func _generate_sun_glows() -> void:
	if _glow_outer and is_instance_valid(_glow_outer):
		_glow_outer.texture = null
		_glow_outer.queue_free()
	_glow_outer = null
	if _glow_inner and is_instance_valid(_glow_inner):
		_glow_inner.texture = null
		_glow_inner.queue_free()
	_glow_inner = null

	var add_mat: Callable = func() -> CanvasItemMaterial:
		var m: CanvasItemMaterial = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		return m

	var glow_tint: Color = _star_glow_tint
	var glow_falloff: float = _corona_falloff
	var make_glow_tex: Callable = func(size_ratio: float) -> Texture2D:
		var size: int = int(texture_size * size_ratio)
		@warning_ignore("unsafe_method_access")
		return TEX.make_circle_texture(
			size,
			func(t: float, _x: int, _y: int) -> Color:
				var brightness: float = (1.0 - t * t) * (1.0 - 0.5 * t)
				brightness *= pow(1.0 - t, glow_falloff * 0.25)
				brightness *= 1.4
				var alpha: float = (1.0 - t * t) * 0.85
				return Color(
					glow_tint.r * brightness,
					glow_tint.g * brightness,
					glow_tint.b * brightness,
					alpha
				)
		)

	# Bump minimum radius so every type has a visible aura. corona_radius_mult
	# still varies per type (M compact ~1.8, O/B extended ~2.6) but never collapses.
	var outer_radius: float = max(_corona_radius_mult, 2.0)
	_glow_outer = Sprite2D.new()
	@warning_ignore("unsafe_cast")
	_glow_outer.texture = make_glow_tex.call(outer_radius) as Texture2D
	_glow_outer.centered = true
	_glow_outer.name = "GlowOuter"
	_glow_outer.z_index = -2
	@warning_ignore("unsafe_cast")
	_glow_outer.material = add_mat.call() as CanvasItemMaterial
	add_child(_glow_outer)

	_glow_inner = Sprite2D.new()
	@warning_ignore("unsafe_cast")
	_glow_inner.texture = make_glow_tex.call(1.4) as Texture2D
	_glow_inner.centered = true
	_glow_inner.name = "GlowInner"
	_glow_inner.z_index = -1
	@warning_ignore("unsafe_cast")
	_glow_inner.material = add_mat.call() as CanvasItemMaterial
	add_child(_glow_inner)


func flash(intensity: float) -> void:
	_collision_flash = max(_collision_flash, intensity)


func _process(delta: float) -> void:
	sun_time += delta
	_shader_mat.set_shader_parameter("u_time", sun_time)

	var breathe: float = sin(sun_time * 0.5) * 0.04 + 1.0
	scale = Vector2(breathe, breathe)

	# Shader owns the photosphere color; modulate stays near-white so the
	# shader's per-channel gradient isn't overridden. A small pulse keeps the
	# "breathing" feel from the original look.
	modulate = Color.WHITE * (sin(sun_time * 1.2) * 0.05 + 0.95)

	var outer_pulse: float = sin(sun_time * 0.25) * 0.12 + 1.12
	var outer_alpha: float = sin(sun_time * 0.2 + 0.5) * 0.2 + 0.4
	var inner_pulse: float = sin(sun_time * 0.35 + 1.2) * 0.06 + 1.06
	var inner_alpha: float = sin(sun_time * 0.3 + 0.3) * 0.15 + 0.6

	if _collision_flash > 0.0:
		var t: float = _collision_flash / 0.6
		var flash_t: float = t * t
		modulate = modulate.lerp(_star_hot_modulate, flash_t * 0.7)
		scale = Vector2(breathe, breathe) * (1.0 + flash_t * 0.15)
		var pulse: float = 1.0 + flash_t * 0.4
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
