extends Node2D


func _ready() -> void:
	@warning_ignore("unsafe_cast")
	var cfg_class: GDScript = load("res://addons/gut/gut_config.gd") as GDScript
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	var cfg: RefCounted = cfg_class.new() as RefCounted
	@warning_ignore("unsafe_cast")
	var runner_scene: PackedScene = load("res://addons/gut/gui/GutRunner.tscn") as PackedScene
	@warning_ignore("unsafe_cast")
	var runner: Node = runner_scene.instantiate() as Node
	@warning_ignore("unsafe_method_access")
	cfg.load_options("res://.gutconfig.json")
	@warning_ignore("unsafe_method_access")
	runner.set_gut_config(cfg)
	add_child(runner)
	@warning_ignore("unsafe_method_access")
	runner.run_tests()
