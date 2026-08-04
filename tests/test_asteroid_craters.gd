extends GutTest

const ASTEROID := preload("res://scripts/bodies/asteroid.gd")

var _archetype_crater_specs := [
	{"name": "C_TYPE", "count": 5, "depth_lo": 0.6, "depth_hi": 0.8},
	{"name": "S_TYPE", "count": 4, "depth_lo": 0.4, "depth_hi": 0.6},
	{"name": "M_TYPE", "count": 3, "depth_lo": 0.2, "depth_hi": 0.4},
	{"name": "X_TYPE", "count": 2, "depth_lo": 0.3, "depth_hi": 0.5},
]


func test_crater_count_per_archetype():
	for archetype in range(_archetype_crater_specs.size()):
		var found := false
		for seed in range(5000):
			var a: Node2D = autofree(ASTEROID.new())
			a._asteroid_seed = seed
			add_child(a)
			if a._archetype == archetype:
				var mat: ShaderMaterial = a._shader_mat
				var count: int = mat.get_shader_parameter("u_crater_count")
				assert_eq(
					count,
					_archetype_crater_specs[archetype].count,
					(
						"archetype %d crater_count=%d"
						% [archetype, _archetype_crater_specs[archetype].count]
					)
				)
				found = true
				break
		assert_true(found, "found seed for archetype %d" % archetype)


func test_crater_depth_per_archetype():
	for archetype in range(_archetype_crater_specs.size()):
		var found := false
		for seed in range(5000):
			var a: Node2D = autofree(ASTEROID.new())
			a._asteroid_seed = seed
			add_child(a)
			if a._archetype == archetype:
				var mat: ShaderMaterial = a._shader_mat
				var depth: float = mat.get_shader_parameter("u_crater_depth")
				assert_between(
					depth,
					_archetype_crater_specs[archetype].depth_lo,
					_archetype_crater_specs[archetype].depth_hi,
					(
						"archetype %d crater_depth in [%.1f, %.1f]"
						% [
							archetype,
							_archetype_crater_specs[archetype].depth_lo,
							_archetype_crater_specs[archetype].depth_hi,
						]
					)
				)
				found = true
				break
		assert_true(found, "found seed for archetype %d" % archetype)


func test_crater_uniforms_present():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	var mat: ShaderMaterial = a._shader_mat
	assert_not_null(mat.get_shader_parameter("u_crater_count"), "has u_crater_count")
	assert_not_null(mat.get_shader_parameter("u_crater_depth"), "has u_crater_depth")


func test_crater_count_in_range():
	for _i in range(50):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		var mat: ShaderMaterial = a._shader_mat
		var count: int = mat.get_shader_parameter("u_crater_count")
		assert_between(count, 1, 8, "crater_count %d in [1, 8]" % count)


func test_crater_depth_in_range():
	for _i in range(50):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		var mat: ShaderMaterial = a._shader_mat
		var depth: float = mat.get_shader_parameter("u_crater_depth")
		assert_between(depth, 0.0, 1.0, "crater_depth %.2f in [0, 1]" % depth)


func test_c_types_have_higher_crater_count_than_m_types():
	const N := 200
	var max_m_count := 0
	var min_c_count := 100
	for _i in range(N):
		var ac: Node2D = autofree(ASTEROID.new())
		add_child(ac)
		if ac._archetype == ASTEROID.AsteroidArchetype.C_TYPE:
			var cnt: int = ac._shader_mat.get_shader_parameter("u_crater_count")
			min_c_count = min(min_c_count, cnt)
	for _i in range(N):
		var am: Node2D = autofree(ASTEROID.new())
		add_child(am)
		if am._archetype == ASTEROID.AsteroidArchetype.M_TYPE:
			var cnt: int = am._shader_mat.get_shader_parameter("u_crater_count")
			max_m_count = max(max_m_count, cnt)

	var msg := "all C-type crater_counts (%d) > all M-type (%d)" % [min_c_count, max_m_count]
	assert_gt(min_c_count, max_m_count, msg)
