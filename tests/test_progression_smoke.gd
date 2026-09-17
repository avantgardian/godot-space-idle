extends GutTest

const PROGRESSION_SCENE: PackedScene = preload("res://scenes/progression.tscn")


func test_progression_scene_instantiates_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(PROGRESSION_SCENE.instantiate())
	add_child(inst)
	await wait_process_frames(2)
	assert_push_error_count(0, "progression.tscn _ready should not push_error")
	assert_push_warning_count(0, "progression.tscn _ready should not push_warning")


func test_progression_scene_runs_frames_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(PROGRESSION_SCENE.instantiate())
	add_child(inst)
	await wait_process_frames(2)

	var spawner: Node = inst.get_node_or_null("%AsteroidSpawner")
	if spawner == null:
		@warning_ignore("unsafe_property_access")
		if "_spawner" in inst:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			spawner = inst._spawner as Node

	for frame: int in range(60):
		if frame == 5 and spawner != null and spawner.has_method("spawn"):
			@warning_ignore("unsafe_method_access")
			spawner.spawn()
		if frame == 10 and inst.has_method("_on_sun_clicked"):
			@warning_ignore("unsafe_method_access")
			inst._on_sun_clicked()
		if frame == 20 and inst.has_method("_toggle_pause"):
			@warning_ignore("unsafe_method_access")
			inst._toggle_pause()
		if frame == 25 and inst.has_method("_toggle_pause"):
			@warning_ignore("unsafe_method_access")
			inst._toggle_pause()
		await wait_process_frames(1)

	assert_push_error_count(0, "progression 60 frames should not push_error")
	assert_push_warning_count(0, "progression 60 frames should not push_warning")


func test_progression_rocket_and_input_without_push_error() -> void:
	seed(42)
	var inst: Node = autofree(PROGRESSION_SCENE.instantiate())
	add_child(inst)
	await wait_process_frames(2)

	# Spawn an asteroid to give rocket a target.
	var spawner: Node = inst.get_node_or_null("%AsteroidSpawner")
	if spawner == null:
		@warning_ignore("unsafe_property_access")
		if "_spawner" in inst:
			@warning_ignore("unsafe_property_access", "unsafe_cast")
			spawner = inst._spawner as Node
	if spawner != null and spawner.has_method("spawn"):
		@warning_ignore("unsafe_method_access")
		spawner.spawn()
	await wait_process_frames(2)

	# Try spaceship rocket fire path (progression.gd:208).
	@warning_ignore("unsafe_property_access")
	var ship: Node = null
	if "_spaceship" in inst:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		ship = inst._spaceship as Node
	if ship == null:
		ship = inst.get_node_or_null("%Spaceship")
	if ship == null:
		ship = inst.get_node_or_null("Spaceship")

	var target: Node2D = null
	if spawner != null and "_asteroids" in spawner:
		@warning_ignore("unsafe_property_access", "unsafe_cast")
		var asteroids: Array = spawner._asteroids as Array
		for a: Variant in asteroids:
			@warning_ignore("unsafe_cast", "unsafe_method_access")
			var node: Node2D = a as Node2D
			if node != null and node.has_method("is_alive"):
				@warning_ignore("unsafe_method_access", "unsafe_cast")
				if node.is_alive() as bool:
					target = node
					break

	if target == null:
		target = autofree(Node2D.new())
		target.position = Vector2(700, 0)
		add_child(target)

	if ship != null and ship.has_method("try_fire") and target != null:
		@warning_ignore("unsafe_method_access", "unsafe_cast")
		var rocket: Node = ship.try_fire(target) as Node
		if rocket != null:
			autofree(rocket)
			add_child(rocket)

	# Input sim toggle_ship_follow (Space)
	var key_space: InputEventKey = InputEventKey.new()
	key_space.keycode = KEY_SPACE
	key_space.pressed = true
	key_space.echo = false
	if inst.has_method("_on_key_pressed"):
		@warning_ignore("unsafe_method_access")
		inst._on_key_pressed(key_space)
	if inst.has_method("_unhandled_input"):
		@warning_ignore("unsafe_method_access")
		inst._unhandled_input(key_space)

	await wait_process_frames(3)
	assert_push_error_count(0, "progression rocket/input should not push_error")
	assert_push_warning_count(0, "progression rocket/input should not push_warning")
