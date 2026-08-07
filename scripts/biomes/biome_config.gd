class_name BiomeConfig
extends Resource

const MAX_FEATURES := 16

@export var polar_cap_lat_deg: float = 0.0
@export var polar_softness: float = 0.1

var _storm_lats: Array[float] = []
var _storm_lons: Array[float] = []
var _storm_sizes: Array[float] = []
var _storm_strengths: Array[float] = []
var _storm_kinds: Array[int] = []


func get_shader() -> Shader:
	push_error("BiomeConfig.get_shader() not implemented")
	return null


func get_texture_size() -> int:
	return 32


func apply_to_shader(_mat: ShaderMaterial) -> void:
	pass


func seed_features(_seed_val: int) -> void:
	pass


func sync_features(_mat: ShaderMaterial) -> void:
	pass


func _seed_storms(
	seed_val: int,
	storm_count: int,
	storm_size_min_deg: float,
	storm_size_max_deg: float,
	kind_count: int
) -> void:
	_storm_lats.clear()
	_storm_lons.clear()
	_storm_sizes.clear()
	_storm_strengths.clear()
	_storm_kinds.clear()
	var count: int = clampi(storm_count, 0, MAX_FEATURES)
	if count == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 53 + 11
	for _i in range(count):
		var lat := rng.randf_range(-1.4, 1.4)
		var lon := rng.randf_range(-PI, PI)
		var size := deg_to_rad(rng.randf_range(storm_size_min_deg, storm_size_max_deg))
		var strength := rng.randf_range(0.4, 0.75)
		var kind: int = rng.randi_range(0, kind_count - 1)
		_storm_lats.append(lat)
		_storm_lons.append(lon)
		_storm_sizes.append(size)
		_storm_strengths.append(strength)
		_storm_kinds.append(kind)


func _sync_storms(mat: ShaderMaterial) -> void:
	var count := _storm_lats.size()
	mat.set_shader_parameter("u_storm_count", count)
	if count == 0:
		return
	var pos := PackedVector2Array()
	var sizes := PackedFloat32Array()
	var strengths := PackedFloat32Array()
	var kinds := PackedInt32Array()
	pos.resize(MAX_FEATURES)
	sizes.resize(MAX_FEATURES)
	strengths.resize(MAX_FEATURES)
	kinds.resize(MAX_FEATURES)
	for i in range(MAX_FEATURES):
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
	mat.set_shader_parameter("u_storm_pos", pos)
	mat.set_shader_parameter("u_storm_size", sizes)
	mat.set_shader_parameter("u_storm_strength", strengths)
	mat.set_shader_parameter("u_storm_kind", kinds)


func _vec3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
