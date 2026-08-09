extends GutTest

const RING := preload("res://scripts/components/ring_system.gd")
const ORBITAL_BODY := preload("res://scripts/bodies/orbital_body.gd")


func _make_ring_parent() -> Node2D:
	var parent: Node2D = autofree(ORBITAL_BODY.new())
	parent.orbit_radius = 500.0
	parent.orbit_period = 48.0
	parent.planet_seed = 42
	parent.axial_tilt_deg = 26.7
	return parent


func test_ring_defaults_are_positive():
	assert_gt(RING.new().ring_inner, 0.0, "inner > 0")
	assert_gt(RING.new().ring_outer, 0.0, "outer > 0")
	assert_gt(RING.new().ring_size, 0.0, "size > 0")
	assert_gt(RING.new().ring_aspect, 0.0, "aspect > 0")


func test_make_ring_material_sets_uniforms():
	var parent := _make_ring_parent()
	add_child(parent)
	var rs: Node2D = autofree(RING.new())
	rs.name = "RingSystem"
	parent.add_child(rs)
	var mat: ShaderMaterial = rs._make_ring_material(1, 100)
	assert_not_null(mat.get_shader_parameter("u_ring_inner"), "u_ring_inner set")
	assert_not_null(mat.get_shader_parameter("u_ring_outer"), "u_ring_outer set")
	assert_not_null(mat.get_shader_parameter("u_cassini"), "u_cassini set")
	assert_not_null(mat.get_shader_parameter("u_cassini_width"), "u_cassini_width set")
	assert_not_null(mat.get_shader_parameter("u_encke"), "u_encke set")
	assert_not_null(mat.get_shader_parameter("u_encke_width"), "u_encke_width set")
	assert_not_null(mat.get_shader_parameter("u_ring_seed"), "u_ring_seed set")
	assert_not_null(mat.get_shader_parameter("u_ring_bright"), "u_ring_bright set")
	assert_not_null(mat.get_shader_parameter("u_ring_dark"), "u_ring_dark set")
	assert_not_null(mat.get_shader_parameter("u_shadow_strength"), "u_shadow_strength set")
	assert_not_null(mat.get_shader_parameter("u_half_mask"), "u_half_mask set")


func test_make_ring_material_half_mask():
	var parent := _make_ring_parent()
	add_child(parent)
	var rs: Node2D = autofree(RING.new())
	parent.add_child(rs)
	var mat_back: ShaderMaterial = rs._make_ring_material(-1, 42)
	var mat_front: ShaderMaterial = rs._make_ring_material(1, 42)
	var half_back: Variant = mat_back.get_shader_parameter("u_half_mask")
	var half_front: Variant = mat_front.get_shader_parameter("u_half_mask")
	assert_not_null(half_back, "half_mask set on back")
	assert_not_null(half_front, "half_mask set on front")


func test_ready_creates_sprites():
	var parent := _make_ring_parent()
	add_child(parent)
	var rs: Node2D = autofree(RING.new())
	rs.name = "RingSystem"
	parent.add_child(rs)
	assert_not_null(rs._ring_sprite_back, "back sprite created")
	assert_not_null(rs._ring_sprite_front, "front sprite created")
	assert_not_null(rs._ring_mat_back, "back material created")
	assert_not_null(rs._ring_mat_front, "front material created")


func test_ring_inner_less_than_outer():
	var parent := _make_ring_parent()
	add_child(parent)
	var rs: Node2D = autofree(RING.new())
	parent.add_child(rs)
	assert_lt(rs.ring_inner, rs.ring_outer, "inner < outer")
