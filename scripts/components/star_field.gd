extends Node2D

const TEX: GDScript = preload("res://scripts/util/texture_utils.gd")
const SPAL: GDScript = preload("res://scripts/util/stellar_palette.gd")

# ── Depth model ──────────────────────────────────────────────────────────
# Three sparse background layers (far → near-bg) sit behind the solar
# plane (z < 0). Two foreground dust layers sit in front of it (z > 0)
# and read as interplanetary mote / zodiacal dust — sparse, soft,
# large bokeh. Void gradient is the deepest backdrop.
#
# Parallax scale: < 0.08 is far (moves slowly = distant), ~1.0 is at
# the planetary plane, > 1.0 is in front (moves faster than the world).
# Blur is per-layer depth-of-field: each layer has a focal depth in
# 0..1 (0 = far void, 1 = closest dust). Camera focus t in 0..1
# (0 = wide system view, 1 = tight orbit view). Blur = |depth - t|
# so background blurs when zoomed in, foreground blurs when zoomed out.

const BG_LAYERS: Array[Dictionary] = [
	{
		"count": 180,
		"min_r": 0.3,
		"max_r": 0.9,
		"min_b": 0.22,
		"max_b": 0.68,
		"motion_scale": 0.010,
		"depth": 0.02,
		"max_blur": 7.0,
	},
	{
		"count": 140,
		"min_r": 0.45,
		"max_r": 1.20,
		"min_b": 0.30,
		"max_b": 0.82,
		"motion_scale": 0.028,
		"depth": 0.18,
		"max_blur": 6.5,
	},
	{
		"count": 90,
		"min_r": 0.60,
		"max_r": 1.60,
		"min_b": 0.38,
		"max_b": 0.95,
		"motion_scale": 0.058,
		"depth": 0.35,
		"max_blur": 5.5,
	},
]

const DUST_LAYERS: Array[Dictionary] = [
	{
		"count": 55,
		"min_r": 1.8,
		"max_r": 3.2,
		"min_b": 0.14,
		"max_b": 0.26,
		"motion_scale": 1.18,
		"depth": 0.88,
		"max_blur": 5.0,
	},
	{
		"count": 32,
		"min_r": 2.4,
		"max_r": 4.2,
		"min_b": 0.12,
		"max_b": 0.22,
		"motion_scale": 1.38,
		"depth": 0.97,
		"max_blur": 6.0,
	},
]

const _STAR_SHADER: Shader = preload("res://shaders/world/star_blur.gdshader")

# Stellar colours come from StellarPalette (OBAFGKM black-body sRGB).
# Dust motes keep their own warm-gray tint (interplanetary, not stellar).

var _sprites: Array[Sprite2D] = []
var _motion_scales: Array[float] = []
var _depths: Array[float] = []
var _max_blurs: Array[float] = []
var _materials: Array[ShaderMaterial] = []
var _focus_t: float = 0.0
var _time: float = 0.0
var _reduced_motion: bool = false
var _bg_container: Node2D
var _fg_container: Node2D
var _void_sprite: Sprite2D


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _reduced_motion:
		return
	_time += delta
	for mat: ShaderMaterial in _materials:
		mat.set_shader_parameter("time", _time)


func generate(seed_val: int, min_zoom: float) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var tile_scale: float = 2.0 / min_zoom
	var screen_size: Vector2 = get_viewport_rect().size
	if screen_size.x < 64.0 or screen_size.y < 64.0:
		screen_size = Vector2(1920, 1080)

	# Ensure containers exist (idempotent if re-generated).
	_ensure_containers()
	_clear_previous()

	# ── Void gradient backdrop (deepest, no parallax) ────────────────
	_generate_void_gradient(screen_size, tile_scale)

	# ── Background star layers ───────────────────────────────────────
	for cfg: Dictionary in BG_LAYERS:
		_generate_star_layer(rng, screen_size, tile_scale, cfg, _bg_container, false)

	# ── Foreground dust layers (in front of planets) ─────────────────
	for cfg: Dictionary in DUST_LAYERS:
		_generate_star_layer(rng, screen_size, tile_scale, cfg, _fg_container, true)

	# Apply initial focus state.
	_apply_focus(_focus_t)


func set_reduced_motion(on: bool) -> void:
	_reduced_motion = on
	var tw: float = 0.0 if on else 1.0
	for mat: ShaderMaterial in _materials:
		mat.set_shader_parameter("twinkle_strength", tw)
		if on:
			mat.set_shader_parameter("time", 0.0)
	if on:
		_time = 0.0


func update_parallax(camera_position: Vector2, camera_zoom: float) -> void:
	var screen_size: Vector2 = get_viewport_rect().size
	if screen_size.x < 64.0 or screen_size.y < 64.0:
		screen_size = Vector2(1920, 1080)
	var world_half: Vector2 = screen_size * 0.5 / camera_zoom

	for i: int in _sprites.size():
		var sprite: Sprite2D = _sprites[i]
		var ms: float = _motion_scales[i]
		var origin: Vector2 = -camera_position * ms
		sprite.position = Vector2(
			origin.x + _align_floor(camera_position.x - world_half.x - origin.x, screen_size.x),
			origin.y + _align_floor(camera_position.y - world_half.y - origin.y, screen_size.y)
		)
	if _void_sprite and is_instance_valid(_void_sprite):
		# Void gradient tiles with the viewport (motion 0) — keep centered
		# on the camera so it never scrolls out.
		_void_sprite.position = Vector2(
			_align_floor(camera_position.x - world_half.x, screen_size.x),
			_align_floor(camera_position.y - world_half.y, screen_size.y)
		)


func set_focus(focus_t: float) -> void:
	var t: float = clamp(focus_t, 0.0, 1.0)
	_focus_t = t
	_apply_focus(t)


func set_blur(amount: float) -> void:
	# Legacy entry point (amount 0..5). Map to focus_t for backwards
	# compat with tests or old call sites.
	var direct: float = clamp(amount / 5.0, 0.0, 1.0)
	set_focus(direct)


func _ensure_containers() -> void:
	if not _bg_container or not is_instance_valid(_bg_container):
		_bg_container = Node2D.new()
		_bg_container.name = "BGContainer"
		_bg_container.z_index = -20
		_bg_container.z_as_relative = false
		add_child(_bg_container)
	if not _fg_container or not is_instance_valid(_fg_container):
		_fg_container = Node2D.new()
		_fg_container.name = "FGContainer"
		_fg_container.z_index = 80
		_fg_container.z_as_relative = false
		add_child(_fg_container)


func _clear_previous() -> void:
	for child: Node in _bg_container.get_children():
		child.queue_free()
	for child: Node in _fg_container.get_children():
		child.queue_free()
	_sprites.clear()
	_motion_scales.clear()
	_depths.clear()
	_max_blurs.clear()
	_materials.clear()
	_void_sprite = null


func _generate_void_gradient(screen_size: Vector2, tile_scale: float) -> void:
	# A very low-frequency nebula tint behind the stars: two large,
	# ultra-soft blobs in dusty indigo / teal to break up flat black.
	var image: Image = Image.create(
		int(screen_size.x), int(screen_size.y), false, Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)
	# Blob 1: indigo upper-left
	var blob1_pos: Vector2 = Vector2(screen_size.x * 0.28, screen_size.y * 0.32)
	var blob1_r: float = min(screen_size.x, screen_size.y) * 0.55
	var blob1_col: Color = Color(0.16, 0.14, 0.32, 0.06)
	_draw_soft_blob(image, blob1_pos, blob1_r, blob1_col)
	# Blob 2: muted teal lower-right
	var blob2_pos: Vector2 = Vector2(screen_size.x * 0.72, screen_size.y * 0.68)
	var blob2_r: float = min(screen_size.x, screen_size.y) * 0.48
	var blob2_col: Color = Color(0.12, 0.28, 0.32, 0.05)
	_draw_soft_blob(image, blob2_pos, blob2_r, blob2_col)
	# Subtle vignette toward center (darker edges already handled by post)
	# Add a central soft lift so the system plane doesn't sit on pure black.
	var center: Vector2 = screen_size * 0.5
	var c_r: float = min(screen_size.x, screen_size.y) * 0.62
	var c_col: Color = Color(0.10, 0.10, 0.22, 0.035)
	_draw_soft_blob(image, center, c_r, c_col)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2(tile_scale, tile_scale)
	sprite.z_index = -100
	sprite.z_as_relative = false
	# No material — void doesn't blur/twinkle.
	_bg_container.add_child(sprite)
	_void_sprite = sprite


func _generate_star_layer(
	rng: RandomNumberGenerator,
	screen_size: Vector2,
	tile_scale: float,
	cfg: Dictionary,
	parent: Node2D,
	is_dust: bool
) -> void:
	@warning_ignore("unsafe_cast")
	var count: int = cfg.count as int
	@warning_ignore("unsafe_cast")
	var min_r: float = cfg.min_r as float
	@warning_ignore("unsafe_cast")
	var max_r: float = cfg.max_r as float
	@warning_ignore("unsafe_cast")
	var min_b: float = cfg.min_b as float
	@warning_ignore("unsafe_cast")
	var max_b: float = cfg.max_b as float
	@warning_ignore("unsafe_cast")
	var motion_scale: float = cfg.motion_scale as float
	@warning_ignore("unsafe_cast")
	var depth: float = cfg.depth as float
	@warning_ignore("unsafe_cast")
	var max_blur: float = cfg.max_blur as float
	var image: Image = Image.create(
		int(screen_size.x), int(screen_size.y), false, Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)

	for _j: int in range(count):
		var x: float = rng.randf_range(0.0, screen_size.x)
		var y: float = rng.randf_range(0.0, screen_size.y)
		# Faint galactic band: ~32% of background stars cluster toward a
		# central horizontal band (simulated Milky Way plane). Cheap,
		# readable, still sparse — not a dense plane texture.
		if not is_dust and rng.randf() < 0.32:
			var band_center: float = screen_size.y * 0.52
			var band_half: float = screen_size.y * 0.18
			y = rng.randf_range(band_center - band_half, band_center + band_half)
			y += rng.randf_range(-screen_size.y * 0.06, screen_size.y * 0.06)
			y = clamp(y, 0.0, screen_size.y)
		# Power-law apparent magnitude: many dim, few bright (mirrors
		# dN/dm ∝ 10^{0.6m} / galactic density; Tycho-2/Gaia bright-star
		# counts double every ~1 mag). pow(raw,1.8) gives long faint tail
		# but lifts the median so the field doesn't read as faint.
		var raw: float = rng.randf()
		var shaped: float = pow(raw, 1.8)
		var brightness: float = lerp(min_b, max_b, shaped)
		# Size–brightness coupling: brighter stars drive larger diffraction
		# discs (Airy-like). Keep layer radii but scale by magnitude.
		var base_radius: float = rng.randf_range(min_r, max_r)
		var radius: float = base_radius * (0.78 + 0.62 * shaped)
		# Long-tail outliers: ~5% of stars at 1.55–2.25× radius with soft
		# outer glow — the "photogenic" bright giants.
		if not is_dust and rng.randf() < 0.05:
			radius *= rng.randf_range(1.55, 2.25)
		var col: Color
		if is_dust:
			# Dust: warm gray, low saturation, very soft alpha.
			var drift: float = rng.randf_range(-0.06, 0.06)
			var base: Color = Color(0.88 + drift, 0.86 + drift * 0.6, 0.82 + drift * 0.3, 1.0)
			var alpha: float = clamp(brightness * 0.95, 0.10, 0.30)
			col = Color(base.r * 0.9, base.g * 0.9, base.b * 0.9, alpha)
			_draw_dust_mote(image, x, y, radius, col)
		else:
			@warning_ignore("unsafe_method_access", "unsafe_cast")
			var tint: Color = SPAL.sample_spectral_color(rng) as Color
			col = Color(tint.r * brightness, tint.g * brightness, tint.b * brightness, 1.0)
			_draw_star_wrapped(image, x, y, radius, col)
			# Subtle halo for the brightest stars (diffraction-like bokeh).
			# Radius coupling already makes bright stars larger; halo makes
			# the top ~15% bloom softly.
			if brightness > 0.52 and radius > 1.05:
				var halo_col: Color = Color(col.r, col.g, col.b, 0.22)
				_draw_halo(image, x, y, radius * 2.35, halo_col)
			# Tiny diffraction spike for the very brightest handful (~2%).
			if brightness > 0.66 and radius > 1.25 and rng.randf() < 0.38:
				_draw_spike(image, x, y, radius, Color(col.r, col.g, col.b, 0.18))

	var texture: ImageTexture = ImageTexture.create_from_image(image)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2(tile_scale, tile_scale)

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _STAR_SHADER
	mat.set_shader_parameter("tiles", tile_scale)
	mat.set_shader_parameter("blur_amount", 0.0)
	mat.set_shader_parameter("time", 0.0)
	mat.set_shader_parameter("twinkle_strength", 0.0 if _reduced_motion or is_dust else 1.0)
	sprite.material = mat

	parent.add_child(sprite)

	_sprites.append(sprite)
	_motion_scales.append(motion_scale)
	_depths.append(depth)
	_max_blurs.append(max_blur)
	_materials.append(mat)


func _apply_focus(focus_t: float) -> void:
	for i: int in _materials.size():
		var max_blur: float = _max_blurs[i]
		if max_blur <= 0.0:
			continue
		var depth: float = _depths[i]
		var blur: float = abs(depth - focus_t) * max_blur
		# Dust closest layer should never fully sharpen — keep a floor
		# so it stays soft and never competes with planets.
		if _motion_scales[i] > 1.0:
			blur = max(blur, 1.2)
		var mat: ShaderMaterial = _materials[i]
		mat.set_shader_parameter("blur_amount", blur)


func _align_floor(offset: float, period: float) -> float:
	return floor(offset / period) * period


func _draw_soft_blob(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var r: int = ceili(radius)
	var cx: int = int(center.x)
	var cy: int = int(center.y)
	for dx: int in range(-r, r + 1):
		for dy: int in range(-r, r + 1):
			var dist: float = Vector2(dx, dy).length()
			if dist > radius:
				continue
			var px: int = cx + dx
			var py: int = cy + dy
			if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
				continue
			var t: float = dist / radius
			# Gaussian falloff.
			var falloff: float = exp(-t * t * 3.2)
			var a: float = color.a * falloff
			if a < 0.002:
				continue
			var existing: Color = image.get_pixel(px, py)
			var blended: Color = Color(color.r, color.g, color.b, a).blend(existing)
			image.set_pixel(px, py, blended)


func _draw_star_wrapped(image: Image, x: float, y: float, radius: float, color: Color) -> void:
	var w: int = image.get_width()
	var h: int = image.get_height()
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


func _draw_star_on_image(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	@warning_ignore("unsafe_method_access")
	TEX.draw_disk_on_image(image, cx, cy, radius, color)


func _draw_halo(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	var r: int = ceili(radius)
	var ix: int = int(cx)
	var iy: int = int(cy)
	for dx: int in range(-r, r + 1):
		for dy: int in range(-r, r + 1):
			var dist: float = Vector2(dx, dy).length()
			if dist > radius:
				continue
			var px: int = ix + dx
			var py: int = iy + dy
			if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
				continue
			var t: float = dist / radius
			var falloff: float = (1.0 - t) * exp(-t * 1.8)
			var a: float = color.a * falloff * 0.55
			if a < 0.003:
				continue
			var existing: Color = image.get_pixel(px, py)
			var src: Color = Color(color.r, color.g, color.b, a)
			image.set_pixel(px, py, src.blend(existing))


func _draw_spike(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	var len_h: int = ceili(radius * 3.2)
	var len_v: int = ceili(radius * 3.2)
	var ix: int = int(cx)
	var iy: int = int(cy)
	var half_w: float = 0.55
	for dx: int in range(-len_h, len_h + 1):
		var adx: float = absf(float(dx))
		var alpha_h: float = (1.0 - adx / float(len_h)) * 0.9
		if alpha_h <= 0.0:
			continue
		for dw: int in range(-1, 1 + 1):
			var py: int = iy + dw
			var px: int = ix + dx
			if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
				continue
			# Soften spike edges across width.
			var w_fall: float = 1.0 - absf(float(dw)) / (half_w + 1.0)
			var a: float = color.a * alpha_h * w_fall * 0.45
			if a < 0.004:
				continue
			var existing: Color = image.get_pixel(px, py)
			image.set_pixel(px, py, Color(color.r, color.g, color.b, a).blend(existing))
	for dy: int in range(-len_v, len_v + 1):
		var ady: float = absf(float(dy))
		var alpha_v: float = (1.0 - ady / float(len_v)) * 0.9
		if alpha_v <= 0.0:
			continue
		for dw: int in range(-1, 1 + 1):
			var px: int = ix + dw
			var py: int = iy + dy
			if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
				continue
			var w_fall: float = 1.0 - absf(float(dw)) / (half_w + 1.0)
			var a: float = color.a * alpha_v * w_fall * 0.45
			if a < 0.004:
				continue
			var existing: Color = image.get_pixel(px, py)
			image.set_pixel(px, py, Color(color.r, color.g, color.b, a).blend(existing))


func _draw_dust_mote(image: Image, cx: float, cy: float, radius: float, color: Color) -> void:
	# Soft bokeh disc: Gaussian alpha falloff, no hard edge.
	var r: int = ceili(radius * 1.6)
	var ix: int = int(cx)
	var iy: int = int(cy)
	for dx: int in range(-r, r + 1):
		for dy: int in range(-r, r + 1):
			var dist: float = Vector2(dx, dy).length()
			if dist > radius * 1.6:
				continue
			var px: int = ix + dx
			var py: int = iy + dy
			if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
				continue
			var t: float = dist / radius
			# Soft Gaussian disc with gentle core.
			var falloff: float = exp(-t * t * 1.4)
			# Slight rim lift for bokeh feel.
			if t > 0.9:
				falloff *= 1.0 - (t - 0.9) / 0.9 * 0.35
			var a: float = color.a * falloff
			if a < 0.003:
				continue
			var existing: Color = image.get_pixel(px, py)
			# Dust accumulates softly — use alpha blend, not blend(existing) invert.
			var src: Color = Color(color.r, color.g, color.b, a)
			# Manual over: src over existing
			var out_a: float = a + existing.a * (1.0 - a)
			if out_a < 0.001:
				continue
			var out_r: float = (src.r * a + existing.r * existing.a * (1.0 - a)) / out_a
			var out_g: float = (src.g * a + existing.g * existing.a * (1.0 - a)) / out_a
			var out_b: float = (src.b * a + existing.b * existing.a * (1.0 - a)) / out_a
			image.set_pixel(px, py, Color(out_r, out_g, out_b, out_a))
