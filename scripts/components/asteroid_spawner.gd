class_name AsteroidSpawner
extends Node

var sun_mass: float = 1.0
var _asteroids: Array[Node2D] = []
var _spawn_timer: float = 5.0
var _gm_unit: float = 0.0
var _asteroid_script: GDScript
var _on_hit_sun: Callable
var _planet_data: Array[Dictionary] = []


func init(asteroid_script: GDScript, gm_unit: float, on_hit_sun: Callable) -> void:
	_asteroid_script = asteroid_script
	_gm_unit = gm_unit
	_on_hit_sun = on_hit_sun


func spawn() -> void:
	var a: Node2D = _asteroid_script.new() as Node2D
	@warning_ignore("unsafe_property_access")
	a.sun_mass = sun_mass
	@warning_ignore("unsafe_property_access")
	a.gm_unit = _gm_unit
	@warning_ignore("unsafe_method_access")
	a.collided_with_sun.connect(_on_asteroid_collided)
	@warning_ignore("unsafe_method_access")
	a.spawn()
	add_child(a)
	_asteroids.append(a)


func _on_asteroid_collided(ast: Node2D) -> void:
	_on_hit_sun.call(ast)


func set_planet_data(data: Array[Dictionary]) -> void:
	_planet_data = data


func _process(delta: float) -> void:
	for i: int in range(_asteroids.size() - 1, -1, -1):
		var a: Node2D = _asteroids[i] as Node2D
		@warning_ignore("unsafe_method_access")
		if not a.is_alive():
			a.queue_free()
			_asteroids.remove_at(i)
		else:
			@warning_ignore("unsafe_property_access", "unsafe_method_access")
			a.sun_mass = sun_mass
			@warning_ignore("unsafe_method_access")
			a.set_planet_data(_planet_data)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		spawn()
		_spawn_timer = randf_range(35.0, 55.0)
