extends Node2D

func _ready() -> void:
	var cfg_class: GDScript = load("res://addons/gut/gut_config.gd")
	var cfg: RefCounted = cfg_class.new()
	var runner_scene: PackedScene = load("res://addons/gut/gui/GutRunner.tscn")
	var runner: Node2D = runner_scene.instantiate()
	cfg.load_options("res://.gutconfig.json")
	runner.set_gut_config(cfg)
	add_child(runner)
	runner.run_tests()
