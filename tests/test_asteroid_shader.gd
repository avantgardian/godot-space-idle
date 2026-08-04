extends GutTest

const ASTEROID := preload("res://scripts/bodies/asteroid.gd")
const ASTEROID_SHADER := preload("res://shaders/bodies/asteroid_surface.gdshader")


func test_asteroid_uses_shader_material():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)
	assert_not_null(a._shader_mat, "asteroid has a ShaderMaterial")
	assert_eq(a._shader_mat.shader, ASTEROID_SHADER, "shader is asteroid_surface.gdshader")


func test_asteroid_light_dir_updates():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)

	a.spawn()
	var light_before: Vector3 = a._shader_mat.get_shader_parameter("u_light_dir")
	assert_ne(light_before.length(), 0.0, "initial light_dir is nonzero")

	a.position = Vector2(100.0, 0.0)
	a._physics_process(0.1)
	var light_after: Vector3 = a._shader_mat.get_shader_parameter("u_light_dir")
	assert_ne(light_after, light_before, "light_dir changes when asteroid moves")


func test_asteroid_shader_has_required_uniforms():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)

	var mat: ShaderMaterial = a._shader_mat
	assert_not_null(mat.get_shader_parameter("u_time"), "has u_time")
	assert_not_null(mat.get_shader_parameter("u_light_dir"), "has u_light_dir")
	assert_not_null(mat.get_shader_parameter("u_ambient"), "has u_ambient")
	assert_not_null(mat.get_shader_parameter("u_seed"), "has u_seed")
	assert_not_null(mat.get_shader_parameter("u_spin_rate"), "has u_spin_rate")
	assert_not_null(mat.get_shader_parameter("u_base_color"), "has u_base_color")
	assert_not_null(mat.get_shader_parameter("u_regolith_hi"), "has u_regolith_hi")
	assert_not_null(mat.get_shader_parameter("u_regolith_lo"), "has u_regolith_lo")
	assert_not_null(mat.get_shader_parameter("u_relief_depth"), "has u_relief_depth")


func test_asteroid_spawn_resets_time():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)

	a.spawn()
	a._physics_process(1.0)
	var t1: float = a._shader_mat.get_shader_parameter("u_time")
	assert_gt(t1, 0.0, "time advances after processing")

	a.spawn()
	var t2: float = a._shader_mat.get_shader_parameter("u_time")
	assert_eq(t2, 0.0, "time resets to 0 after spawn")


func test_asteroid_no_sprite_rotation():
	var a: Node2D = autofree(ASTEROID.new())
	add_child(a)

	a.spawn()
	var rot_before: float = a._sprite.rotation
	a._physics_process(1.0)
	var rot_after: float = a._sprite.rotation
	assert_eq(rot_after, rot_before, "sprite rotation stays zero (shader handles spin)")
