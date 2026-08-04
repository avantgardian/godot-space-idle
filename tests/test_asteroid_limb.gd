extends GutTest

const ASTEROID := preload("res://scripts/bodies/asteroid.gd")

var _archetype_limb_specs := [
	{"name": "C_TYPE", "strength_lo": 0.02, "strength_hi": 0.10},
	{"name": "S_TYPE", "strength_lo": 0.15, "strength_hi": 0.25},
	{"name": "M_TYPE", "strength_lo": 0.30, "strength_hi": 0.40},
	{"name": "X_TYPE", "strength_lo": 0.20, "strength_hi": 0.30},
]


func test_limb_strength_per_archetype():
	for archetype in range(_archetype_limb_specs.size()):
		var found := false
		for seed in range(5000):
			var a: Node2D = autofree(ASTEROID.new())
			a._asteroid_seed = seed
			add_child(a)
			if a._archetype == archetype:
				var mat: ShaderMaterial = a._shader_mat
				var strength: float = mat.get_shader_parameter("u_limb_strength")
				assert_between(
					strength,
					_archetype_limb_specs[archetype].strength_lo,
					_archetype_limb_specs[archetype].strength_hi,
					(
						"archetype %d limb_strength %.3f in [%.2f, %.2f]"
						% [
							archetype,
							strength,
							_archetype_limb_specs[archetype].strength_lo,
							_archetype_limb_specs[archetype].strength_hi,
						]
					)
				)
				found = true
				break
		assert_true(found, "found seed for archetype %d" % archetype)


func test_limb_strength_uniform_present():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	var mat: ShaderMaterial = a._shader_mat
	assert_not_null(mat.get_shader_parameter("u_limb_strength"), "has u_limb_strength")


func test_limb_strength_in_bounds():
	for _i in range(50):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		var mat: ShaderMaterial = a._shader_mat
		var strength: float = mat.get_shader_parameter("u_limb_strength")
		assert_between(strength, 0.0, 0.5, "limb_strength %.3f in [0, 0.5]" % strength)


func test_m_types_brighter_limb_than_c_types():
	const N := 200
	var max_c_strength := 0.0
	var min_m_strength := 1.0
	for _i in range(N):
		var a: Node2D = autofree(ASTEROID.new())
		add_child(a)
		var strength: float = a._shader_mat.get_shader_parameter("u_limb_strength")
		if a._archetype == ASTEROID.AsteroidArchetype.C_TYPE:
			max_c_strength = max(max_c_strength, strength)
		elif a._archetype == ASTEROID.AsteroidArchetype.M_TYPE:
			min_m_strength = min(min_m_strength, strength)

	var msg := (
		"all M-type limb_strengths (%.3f) > all C-type (%.3f)" % [min_m_strength, max_c_strength]
	)
	assert_gt(min_m_strength, max_c_strength, msg)
