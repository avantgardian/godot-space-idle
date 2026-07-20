class_name OrbitalBody
extends Node2D

const _TEX := preload("res://scripts/texture_utils.gd")
const _TRAIL := preload("res://scripts/trail_component.gd")
const DU := preload("res://scripts/draw_utils.gd")
const _PLANET_SHADER := preload("res://shaders/planet_surface.gdshader")
const _ATM_SHADER := preload("res://shaders/atmosphere_rim.gdshader")
const PAL := preload("res://scripts/planet_palette.gd")
var _sprite: Sprite2D
var _atm_sprite: Sprite2D
var _atm_mat: ShaderMaterial

@export var orbit_radius: float = 500.0
@export var orbit_period: float = 48.0
@export var start_angle: float = 0.0

var sun_mass: float = 1.0
@export var mass: float = 1.0
@export var collision_radius: float = 20.0
var _pos: Vector2
var _vel: Vector2
var _dead: bool = false
@export var trail_max: int = 1200
var _trail_component: Node

@export var use_shader: bool = false
@export var planet_type: StringName = &""
@export var planet_seed: int = 0
@export var axial_tilt_deg: float = 0.0
@export var rotation_rate: float = 0.05

# Rocky biome params (#104). Per-planet scripts override these to taste.
# Default u_polar_cap_lat = 0 → no caps.
@export var crater_count: int = 0
@export var crater_size_min_deg: float = 3.0
@export var crater_size_max_deg: float = 9.0
@export var polar_cap_lat_deg: float = 0.0
@export var polar_softness: float = 0.1

# Greenhouse biome params (#105). All default to inert values; per-planet
# scripts (e.g. Venus) opt in via planet_type = &"greenhouse".
@export var cloud_swirl_amp: float = 0.15
@export var cloud_swirl_freq: float = 6.0
@export var cloud_contrast: float = 0.6
@export var limb_brighten: float = 0.0
@export var surface_lava_leak: float = 0.0:
	set(val):
		surface_lava_leak = val
		if _shader_mat:
			_shader_mat.set_shader_parameter("u_surface_lava_leak", val)

# Terrestrial biome params (#106). All default to inert values; per-planet
# scripts (e.g. Earth) opt in via planet_type = &"terrestrial". The polar
# cutoff reuses the rocky #104 polar_cap_lat_deg / polar_softness exports
# so a single uniform set governs cap placement across biomes.
@export var sea_level: float = 0.5
@export var ocean_shelf_depth: float = 0.15
@export var cloud_coverage: float = 0.45
@export var cloud_spin_rate: float = 0.15
@export var cloud_scale: float = 3.0
@export var specular_power: float = 64.0
@export var city_lights: float = 0.0

# Gas giant biome params (#107). All default to inert values; per-planet
# scripts (e.g. Jupiter) opt in via planet_type = &"gas_giant".
@export var band_count: int = 12
@export var band_sharp: float = 0.15
@export var shear_amp: float = 0.10
@export var band_warp: float = 0.05
@export var storm_count: int = 0
@export var storm_size_min_deg: float = 2.0
@export var storm_size_max_deg: float = 8.0
@export var storm_stretch: float = 3.0

# Ice giant biome params (#109). All default to Uranus values (featureless).
# Per-planet scripts (Neptune) increase contrast/haze/storm counts to taste.
@export var ice_variant: int = 0           # 0 = Uranus, 1 = Neptune
@export var ice_band_contrast: float = 0.03
@export var ice_haze_strength: float = 0.0

# Atmosphere rim glow (#110). Per-planet scripts opt in by setting
# atm_color to a non-transparent PlanetPalette token. Default alpha 0
# → no rim sprite is generated at all (Mercury, dead moons).
# atm_thickness_mult controls the size of the rim sprite relative to
# the planet disk — needs a generous buffer (>= 2.0) so the halo fades
# to ~0 well inside the sprite's edge (otherwise the square texture
# boundary becomes visible as a hard clip).
@export var atm_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var atm_thickness_mult: float = 2.5
@export var atm_intensity: float = 1.2
@export var atm_ambient: float = 0.05

var _planet_time: float = 0.0
var _shader_mat: ShaderMaterial

const BIOME_NONE         := 0
const BIOME_ROCKY        := 1
const BIOME_GREENHOUSE   := 2
const BIOME_TERRESTRIAL  := 3
const BIOME_GAS_GIANT    := 4
const BIOME_ICE_GIANT    := 5
const _MAX_CRATERS := 16

const STORM_RUST: int = 0
const STORM_WHITE: int = 1
const STORM_DARK: int = 2

var _crater_lats: Array[float] = []
var _crater_lons: Array[float] = []
var _crater_sizes: Array[float] = []
var _crater_strengths: Array[float] = []

var _storm_lats: Array[float] = []
var _storm_lons: Array[float] = []
var _storm_sizes: Array[float] = []
var _storm_strengths: Array[float] = []
var _storm_kinds: Array[int] = []   # 0 = rust, 1 = white, 2 = dark

signal collided_with_sun

func is_dead() -> bool:
	return _dead

func disable():
	if _trail_component:
		_trail_component.fade_out()
	_dead = true
	visible = false

func get_vel() -> Vector2:
	return _vel

func set_vel(v: Vector2):
	_vel = v

func _ready():
	_generate_texture()
	_reset()

func setup_trail(color: Color):
	_trail_component = _TRAIL.new()
	var head := DU.trail_head(color)
	var tail := DU.trail_tail(color)
	_trail_component.setup(tail, head, 1.5, trail_max)
	add_child(_trail_component)

func _generate_texture():
	var tex_size := _get_planet_texture_size()
	_sprite = Sprite2D.new()
	if use_shader:
		_sprite.texture = _make_white_disk_mask(tex_size)
	else:
		_sprite.texture = _TEX.make_circle_texture(tex_size, _get_planet_color)
	_sprite.centered = true
	add_child(_sprite)
	if use_shader:
		_apply_planet_shader()
		_apply_atmosphere_shader(tex_size)

func _make_white_disk_mask(size: int) -> ImageTexture:
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
				if t > 0.98:
					alpha = 1.0 - (t - 0.98) / 0.02
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _apply_planet_shader():
	var seed_val := planet_seed
	if seed_val == 0:
		seed_val = hash(name)
	# Clamp the seed to a small range before passing to the shader uniform.
	# The shader builds per-pixel coords as `vec2(lon, lat) * scale +
	# vec2(u_seed * 1.7, u_seed * 0.93)`. float32 has ~7 decimal digits of
	# precision, so a multi-billion hash value absorbs the few-unit lon/lat
	# variation across the disk — and the per-pixel hash21 input becomes
	# identical everywhere, producing a uniform fbm (flat texture, no
	# continents/craters/clouds). Clamping to [0, 1023) keeps the offset
	# within float32 precision while still varying per-instance. (Same bug
	# silently hid all Mars/Mercury surface texture since #104.)
	seed_val = abs(seed_val) % 1023
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = _PLANET_SHADER
	var biome := _get_biome_mode()
	_shader_mat.set_shader_parameter("u_biome_mode", biome)
	_shader_mat.set_shader_parameter("u_time", 0.0)
	_shader_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_shader_mat.set_shader_parameter("u_ambient", 0.06)
	_shader_mat.set_shader_parameter("u_night_rim", 0.4)
	_shader_mat.set_shader_parameter("u_limb", 0.35)
	_shader_mat.set_shader_parameter("u_axial_tilt", deg_to_rad(axial_tilt_deg))
	_shader_mat.set_shader_parameter("u_spin_rate", rotation_rate)
	_shader_mat.set_shader_parameter("u_seed", seed_val)
	var bc := _get_shader_base_color()
	_shader_mat.set_shader_parameter("u_base_color", _TEX.vec3(bc))
	_shader_mat.set_shader_parameter("u_noise_scale", 4.0)
	_shader_mat.set_shader_parameter("u_noise_amp", 0.15)
	# Rocky biome (#104) uniforms. Defaults are harmless (no caps, no craters)
	# so non-rocky planets remain pixel-identical to the #102 path.
	var rocky_hi := _get_rocky_hi()
	var rocky_lo := _get_rocky_lo()
	_shader_mat.set_shader_parameter("u_rocky_hi", _TEX.vec3(rocky_hi))
	_shader_mat.set_shader_parameter("u_rocky_lo", _TEX.vec3(rocky_lo))
	_shader_mat.set_shader_parameter("u_surface_grain_amp", 0.15)
	_shader_mat.set_shader_parameter("u_polar_cap_lat", deg_to_rad(polar_cap_lat_deg))
	_shader_mat.set_shader_parameter("u_polar_softness", polar_softness)
	var polar_col := _get_polar_cap_color()
	_shader_mat.set_shader_parameter("u_polar_cap_color", _TEX.vec3(polar_col))
	# Greenhouse biome (#105) uniforms. Defaults are inert (no limb brighten,
	# no lava leak) so non-greenhouse planets see no change.
	var v_hi := _get_greenhouse_cloud_hi()
	var v_lo := _get_greenhouse_cloud_lo()
	_shader_mat.set_shader_parameter("u_venus_cloud_hi", _TEX.vec3(v_hi))
	_shader_mat.set_shader_parameter("u_venus_cloud_lo", _TEX.vec3(v_lo))
	_shader_mat.set_shader_parameter("u_cloud_swirl_amp", cloud_swirl_amp)
	_shader_mat.set_shader_parameter("u_cloud_swirl_freq", cloud_swirl_freq)
	_shader_mat.set_shader_parameter("u_cloud_contrast", cloud_contrast)
	_shader_mat.set_shader_parameter("u_limb_brighten", limb_brighten)
	_shader_mat.set_shader_parameter("u_surface_lava_leak", surface_lava_leak)
	var lava_col := _get_lava_color()
	_shader_mat.set_shader_parameter("u_lava_color", _TEX.vec3(lava_col))
	# Terrestrial biome (#106) uniforms. Reuses u_polar_cap_lat and
	# u_polar_softness (already set above from the rocky #104 exports) so a
	# single set of polar params governs cap placement across biomes.
	var ocean_deep := _get_terra_ocean_deep()
	var ocean_shallow := _get_terra_ocean_shallow()
	var land_trop := _get_terra_land_tropical()
	var land_des := _get_terra_land_desert()
	var land_tun := _get_terra_land_tundra()
	var ice := _get_terra_ice_cap()
	var cloud := _get_terra_cloud_white()
	var spec := _get_terra_ocean_specular()
	_shader_mat.set_shader_parameter("u_ocean_deep", _TEX.vec3(ocean_deep))
	_shader_mat.set_shader_parameter("u_ocean_shallow", _TEX.vec3(ocean_shallow))
	_shader_mat.set_shader_parameter("u_land_tropical", _TEX.vec3(land_trop))
	_shader_mat.set_shader_parameter("u_land_desert", _TEX.vec3(land_des))
	_shader_mat.set_shader_parameter("u_land_tundra", _TEX.vec3(land_tun))
	_shader_mat.set_shader_parameter("u_terra_ice_cap", _TEX.vec3(ice))
	_shader_mat.set_shader_parameter("u_terra_cloud_white", _TEX.vec3(cloud))
	_shader_mat.set_shader_parameter("u_terra_specular", _TEX.vec3(spec))
	_shader_mat.set_shader_parameter("u_sea_level", sea_level)
	_shader_mat.set_shader_parameter("u_ocean_shelf_depth", ocean_shelf_depth)
	_shader_mat.set_shader_parameter("u_cloud_coverage", cloud_coverage)
	_shader_mat.set_shader_parameter("u_cloud_spin_rate", cloud_spin_rate)
	_shader_mat.set_shader_parameter("u_cloud_scale", cloud_scale)
	_shader_mat.set_shader_parameter("u_specular_power", specular_power)
	_shader_mat.set_shader_parameter("u_city_lights", city_lights)
	# Gas giant biome (#107) uniforms. Defaults are inert so non-gas-giant
	# planets see no change.
	var gb_hi := _get_gas_band_hi()
	var gb_lo := _get_gas_band_lo()
	var sr := _get_storm_rust()
	var sw := _get_storm_white()
	_shader_mat.set_shader_parameter("u_gas_band_hi", _TEX.vec3(gb_hi))
	_shader_mat.set_shader_parameter("u_gas_band_lo", _TEX.vec3(gb_lo))
	_shader_mat.set_shader_parameter("u_storm_rust", _TEX.vec3(sr))
	_shader_mat.set_shader_parameter("u_storm_white", _TEX.vec3(sw))
	_shader_mat.set_shader_parameter("u_band_count", band_count)
	_shader_mat.set_shader_parameter("u_band_sharp", band_sharp)
	_shader_mat.set_shader_parameter("u_shear_amp", shear_amp)
	_shader_mat.set_shader_parameter("u_band_warp", band_warp)
	_shader_mat.set_shader_parameter("u_storm_stretch", storm_stretch)
	# Ice giant biome (#109) uniforms. Defaults are Uranus values (inert).
	var ice_base := _get_ice_base_color()
	var ice_haze := _get_ice_haze_color()
	var ice_dark := _get_ice_storm_dark()
	_shader_mat.set_shader_parameter("u_ice_base_color", _TEX.vec3(ice_base))
	_shader_mat.set_shader_parameter("u_ice_band_contrast", ice_band_contrast)
	_shader_mat.set_shader_parameter("u_ice_haze_color", _TEX.vec3(ice_haze))
	_shader_mat.set_shader_parameter("u_ice_haze_strength", ice_haze_strength)
	_shader_mat.set_shader_parameter("u_ice_storm_dark", _TEX.vec3(ice_dark))
	_shader_mat.set_shader_parameter("u_ice_variant", ice_variant)
	if biome == BIOME_ICE_GIANT:
		_shader_mat.set_shader_parameter("u_limb", 0.30)
	# Crater / storm uniforms seeded below; zeros here as placeholders.
	_shader_mat.set_shader_parameter("u_crater_count", 0)
	_shader_mat.set_shader_parameter("u_storm_count", 0)
	_sprite.material = _shader_mat
	if biome == BIOME_ROCKY:
		_seed_craters(seed_val)
		_sync_crater_uniforms()
	if biome == BIOME_GAS_GIANT:
		_seed_storms(seed_val)
		_sync_storm_uniforms()
	if biome == BIOME_ICE_GIANT:
		_seed_storms(seed_val)
		_sync_storm_uniforms()

func _get_biome_mode() -> int:
	match planet_type:
		&"rocky": return BIOME_ROCKY
		&"greenhouse": return BIOME_GREENHOUSE
		&"terrestrial": return BIOME_TERRESTRIAL
		&"gas_giant": return BIOME_GAS_GIANT
		&"ice_giant": return BIOME_ICE_GIANT
		_:
			return BIOME_NONE

func _get_rocky_hi() -> Color:
	return PAL.ROCKY_MERCURY_HI

func _get_rocky_lo() -> Color:
	return PAL.ROCKY_MERCURY_LO

func _get_polar_cap_color() -> Color:
	return PAL.ROCKY_MARS_ICE

func _get_greenhouse_cloud_hi() -> Color:
	return PAL.VENUS_CLOUD_HI

func _get_greenhouse_cloud_lo() -> Color:
	return PAL.VENUS_CLOUD_LO

func _get_lava_color() -> Color:
	return PAL.VENUS_SURFACE_LAVA

# Terrestrial biome (#106) color hooks. Per-planet scripts override these to
# swap biome tokens (e.g. an arid terra could swap land_tropical for desert).
func _get_terra_ocean_deep() -> Color:
	return PAL.TERRA_OCEAN_DEEP

func _get_terra_ocean_shallow() -> Color:
	return PAL.TERRA_OCEAN_SHALLOW

func _get_terra_land_tropical() -> Color:
	return PAL.TERRA_LAND_TROPICAL

func _get_terra_land_desert() -> Color:
	return PAL.TERRA_LAND_DESERT

func _get_terra_land_tundra() -> Color:
	return PAL.TERRA_LAND_TUNDRA

func _get_terra_ice_cap() -> Color:
	return PAL.TERRA_ICE_CAP

func _get_terra_cloud_white() -> Color:
	return PAL.TERRA_CLOUD_WHITE

func _get_terra_ocean_specular() -> Color:
	return PAL.TERRA_OCEAN_SPECULAR

# Gas giant biome (#107) color hooks. Per-planet scripts override these to
# swap band tokens (e.g. Saturn could override to SATURN_BAND_*).
func _get_gas_band_hi() -> Color:
	return PAL.GAS_BAND_TAN_HI

func _get_gas_band_lo() -> Color:
	return PAL.GAS_BAND_TAN_LO

func _get_storm_rust() -> Color:
	return PAL.GAS_STORM_RUST

func _get_storm_white() -> Color:
	return PAL.GAS_STORM_WHITE

# Ice giant biome (#109) color hooks. Per-planet scripts override these to
# swap biome tokens (Uranus vs Neptune color saturation).
func _get_ice_base_color() -> Color:
	return PAL.ICE_METHANE_BLUE

func _get_ice_haze_color() -> Color:
	return PAL.ICE_HAZE_WHITE

func _get_ice_storm_dark() -> Color:
	return PAL.ICE_STORM_DARK

func _seed_craters(seed_val: int):
	_crater_lats.clear()
	_crater_lons.clear()
	_crater_sizes.clear()
	_crater_strengths.clear()
	var count: int = clamp(crater_count, 0, _MAX_CRATERS)
	if count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 31 + 7
	for i in range(count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(crater_size_min_deg, crater_size_max_deg))
		var strength := rng.randf_range(0.45, 0.80)
		_crater_lats.append(lat)
		_crater_lons.append(lon)
		_crater_sizes.append(size)
		_crater_strengths.append(strength)

func _sync_crater_uniforms():
	if not _shader_mat:
		return
	var count := _crater_lats.size()
	_shader_mat.set_shader_parameter("u_crater_count", count)
	if count == 0:
		return
	var pos := PackedVector2Array()
	var sizes := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	pos.resize(_MAX_CRATERS)
	sizes.resize(_MAX_CRATERS)
	strengths.resize(_MAX_CRATERS)
	for i in range(_MAX_CRATERS):
		if i < count:
			pos[i] = Vector2(_crater_lats[i], _crater_lons[i])
			sizes[i] = _crater_sizes[i]
			strengths[i] = _crater_strengths[i]
		else:
			pos[i] = Vector2.ZERO
			sizes[i] = 0.0
			strengths[i] = 0.0
	_shader_mat.set_shader_parameter("u_crater_pos", pos)
	_shader_mat.set_shader_parameter("u_crater_size", sizes)
	_shader_mat.set_shader_parameter("u_crater_strength", strengths)

func _seed_storms(seed_val: int):
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	var count: int = clamp(storm_count, 0, _MAX_CRATERS)
	if count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 53 + 11
	for i in range(count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(storm_size_min_deg, storm_size_max_deg))
		var strength := rng.randf_range(0.4, 0.75)
		var kind: int = rng.randi_range(0, 1)
		_storm_lats.append(lat)
		_storm_lons.append(lon)
		_storm_sizes.append(size)
		_storm_strengths.append(strength)
		_storm_kinds.append(kind)

func _sync_storm_uniforms():
	if not _shader_mat:
		return
	var count := _storm_lats.size()
	_shader_mat.set_shader_parameter("u_storm_count", count)
	if count == 0:
		return
	var pos := PackedVector2Array()
	var sizes := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	var kinds := PackedInt32Array()
	pos.resize(_MAX_CRATERS)
	sizes.resize(_MAX_CRATERS)
	strengths.resize(_MAX_CRATERS)
	kinds.resize(_MAX_CRATERS)
	for i in range(_MAX_CRATERS):
		if i < count:
			pos[i] = Vector2(_storm_lats[i], _storm_lons[i])
			sizes[i] = _storm_sizes[i]
			strengths[i] = _storm_strengths[i]
			kinds[i] = _storm_kinds[i]
		else:
			pos[i] = Vector2.ZERO
			sizes[i] = 0.0
			strengths[i] = 0.0
			kinds[i] = 0
	_shader_mat.set_shader_parameter("u_storm_pos", pos)
	_shader_mat.set_shader_parameter("u_storm_size", sizes)
	_shader_mat.set_shader_parameter("u_storm_strength", strengths)
	_shader_mat.set_shader_parameter("u_storm_kind", kinds)

func _apply_atmosphere_shader(tex_size: int):
	# Gated by atm_color.a > 0 — Mercury and dead moons produce no rim sprite.
	if atm_color.a <= 0.0:
		return
	# The rim sprite is a square slightly larger than the planet disk.
	# We use a fully-opaque white texture (no disk mask) so the shader has
	# pixels to glow through OUTSIDE the planet silhouette — the shader
	# itself does all the geometric falloff. We need the planet's apparent
	# disk radius inside the rim sprite's UV to equal 1.0 in shader UV
	# space, so the rim sprite must be sized as planet_tex / (1.0 / thickness_mult)
	# -> planet_tex * thickness_mult. Centered + same scale as planet sprite.
	var atm_tex_size: int = int(tex_size * atm_thickness_mult)
	if atm_tex_size < 4:
		return
	_atm_sprite = Sprite2D.new()
	_atm_sprite.texture = _make_opaque_white_square(atm_tex_size)
	_atm_sprite.centered = true
	# Z above the planet so the halo draws OVER the orbit line (trail) and
	# over the planet disk — atmospheres render both in front of and around
	# the disk on the day side. Additive blend won't blow out the surface
	# because the rim kernel is 0 inside r < 1.0 (the planet disk).
	_atm_sprite.z_index = 1
	add_child(_atm_sprite)
	_atm_mat = ShaderMaterial.new()
	_atm_mat.shader = _ATM_SHADER
	_atm_mat.set_shader_parameter("u_light_dir", Vector3(-1.0, 0.0, 0.0))
	_atm_mat.set_shader_parameter("u_atm_color", _TEX.vec3(atm_color))
	_atm_mat.set_shader_parameter("u_atm_intensity", atm_intensity)
	_atm_mat.set_shader_parameter("u_atm_ambient", atm_ambient)
	_atm_mat.set_shader_parameter("u_atm_thickness", 0.03)
	_atm_mat.set_shader_parameter("u_planet_radius_uv", 1.0 / atm_thickness_mult)
	_atm_sprite.material = _atm_mat

func _make_opaque_white_square(size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(image)

func _get_shader_base_color() -> Color:
	# Per-biome issues (#104-#109) override this to return a PlanetPalette
	# token appropriate to their biome. The default path here preserves the
	# pre-shader identity color (set by each planet script) so the day/night
	# terminator reads against a familiar tint during the rollout.
	var pc = get("planet_color")
	if pc is Color:
		return pc
	# Fallback: photometric Earth-ocean blue, so a planet with no identity
	# color still renders as a plausible sphere rather than flat white.
	return PAL.TERRA_OCEAN_DEEP

func _get_planet_texture_size() -> int:
	return 32

func _get_planet_color(_t: float, _x: int, _y: int) -> Color:
	return Color.WHITE

func _reset():
	var gm := _initial_gm()
	_pos = Vector2(orbit_radius * cos(start_angle), orbit_radius * sin(start_angle))
	var tangent := Vector2(-_pos.y, _pos.x).normalized()
	_vel = tangent * sqrt(gm / orbit_radius)
	position = _pos
	_dead = false
	visible = true
	if _trail_component:
		_trail_component.clear()

static func sun_collision_r(mass_solar: float) -> float:
	return (128.0 + sqrt(mass_solar) * 8.0) * 0.85

func _initial_gm() -> float:
	return 4.0 * PI * PI * orbit_radius * orbit_radius * orbit_radius / (orbit_period * orbit_period)

func _process(delta):
	if _dead:
		return

	var gm := _initial_gm() * sun_mass
	var r2 := _pos.length_squared()
	if r2 < 1.0:
		r2 = 1.0
	var r := sqrt(r2)
	var acc := -gm / r2 * _pos / r
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	if _shader_mat:
		_planet_time += delta
		_shader_mat.set_shader_parameter("u_time", _planet_time)
		var dir := -position
		if dir.length_squared() > 0.0:
			dir = dir.normalized()
		var light_vec := Vector3(dir.x, dir.y, 0.0)
		_shader_mat.set_shader_parameter("u_light_dir", light_vec)
		if _atm_mat:
			_atm_mat.set_shader_parameter("u_light_dir", light_vec)

	var sun_r := sun_collision_r(sun_mass) + collision_radius
	if r < sun_r:
		if _trail_component:
			_trail_component.fade_out()
		_dead = true
		visible = false
		collided_with_sun.emit()

	if _trail_component:
		_trail_component.record(position)
