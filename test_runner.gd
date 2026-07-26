extends SceneTree

func _init() -> void:
	var max_iter: int = 20
	var iter: int = 0
	while Engine.get_main_loop() == null and iter < max_iter:
		await create_timer(0.01).timeout
		iter += 1

	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		quit(0)
		return

	var cfg_class: GDScript = load("res://addons/gut/gut_config.gd")
	var cfg: RefCounted = cfg_class.new()
	var runner_scene: PackedScene = load("res://addons/gut/gui/GutRunner.tscn")
	var runner: Node2D = runner_scene.instantiate()

	cfg.load_options("res://.gutconfig.json")
	runner.visible = false
	runner.set_gut_config(cfg)
	get_root().add_child(runner)
	runner.run_tests(false)
