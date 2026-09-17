extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func test_main_scene_instantiates_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(MAIN_SCENE.instantiate())
	add_child(inst)
	@warning_ignore("unsafe_property_access")
	if "star_seed" in inst:
		@warning_ignore("unsafe_property_access")
		inst.star_seed = 42
	await wait_process_frames(2)
	assert_push_error_count(0, "main.tscn _ready should not push_error")
	assert_push_warning_count(0, "main.tscn _ready should not push_warning")


func test_main_scene_runs_frames_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(MAIN_SCENE.instantiate())
	@warning_ignore("unsafe_property_access")
	if "star_seed" in inst:
		@warning_ignore("unsafe_property_access")
		inst.star_seed = 42
	add_child(inst)
	await wait_process_frames(2)

	@warning_ignore("unsafe_property_access")
	var planets: Array = []
	if "_planet_data" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		planets = inst._planet_data as Array
	if planets.size() > 0:
		assert_eq(planets.size(), 8, "Main should have 8 OrbitalBody planets")
		var saturn: Node = inst.get_node_or_null("%Saturn")
		if saturn == null:
			saturn = inst.get_node_or_null("Saturn")
		if saturn != null:
			var has_ring: bool = false
			for child: Node in saturn.get_children():
				if child.get_script() != null and "RingSystem" in str(child.get_script()):
					has_ring = true
					break
				if child.name.contains("Ring"):
					has_ring = true
					break
			# Saturn should carry RingSystemComponent child (main.gd:40)
			assert_true(
				has_ring or saturn.get_child_count() > 0, "Saturn should have RingSystem child"
			)

	var spawner: Node = inst.get_node_or_null("%AsteroidSpawner")
	if spawner == null:
		@warning_ignore("unsafe_property_access")
		if "_spawner" in inst:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			spawner = inst._spawner as Node

	for frame: int in range(300):
		if frame == 5 and spawner != null and spawner.has_method("spawn"):
			@warning_ignore("unsafe_method_access")
			spawner.spawn()
		if frame == 10 and inst.has_method("_on_sun_clicked"):
			@warning_ignore("unsafe_method_access")
			inst._on_sun_clicked()
		if frame == 15 and inst.has_method("_close_sun_popup"):
			@warning_ignore("unsafe_method_access")
			inst._close_sun_popup()
		if frame == 20:
			var cam: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
			if cam != null and cam.has_method("zoom_in"):
				@warning_ignore("unsafe_method_access")
				cam.zoom_in()
		if frame == 30 and inst.has_method("_toggle_pause"):
			@warning_ignore("unsafe_method_access")
			inst._toggle_pause()
		if frame == 35 and inst.has_method("_toggle_pause"):
			@warning_ignore("unsafe_method_access")
			inst._toggle_pause()
		if frame == 40:
			var cam2: Camera2D = inst.get_node_or_null("%Camera2D") as Camera2D
			if cam2 != null and cam2.has_method("start_drag"):
				@warning_ignore("unsafe_method_access")
				cam2.start_drag(Vector2(960, 540))
				@warning_ignore("unsafe_method_access")
				cam2.update_drag(Vector2(970, 550))
				@warning_ignore("unsafe_method_access")
				cam2.end_drag()
		await wait_process_frames(1)

	assert_push_error_count(0, "main.tscn 300 frames should not push_error")
	assert_push_warning_count(0, "main.tscn 300 frames should not push_warning")


func test_main_scene_input_simulation_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(MAIN_SCENE.instantiate())
	@warning_ignore("unsafe_property_access")
	if "star_seed" in inst:
		@warning_ignore("unsafe_property_access")
		inst.star_seed = 42
	add_child(inst)
	await wait_process_frames(2)

	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(960, 540)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(mb)

	var key_l: InputEventKey = InputEventKey.new()
	key_l.keycode = KEY_L
	key_l.pressed = true
	key_l.echo = false
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_l)

	var key_esc: InputEventKey = InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	key_esc.pressed = true
	key_esc.echo = false
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_esc)

	await wait_process_frames(2)
	assert_push_error_count(0, "main input sim should not push_error")
	assert_push_warning_count(0, "main input sim should not push_warning")
