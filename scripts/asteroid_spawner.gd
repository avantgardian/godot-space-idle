class_name AsteroidSpawner
extends Node

var _asteroids: Array = []
var _spawn_timer: float = 5.0
var sun_mass: float = 1.0
var _gm_unit: float = 0.0
var _asteroid_script: GDScript
var _on_hit_sun: Callable
var _planet_data: Array[Dictionary] = []

func init(asteroid_script: GDScript, gm_unit: float, on_hit_sun: Callable):
	_asteroid_script = asteroid_script
	_gm_unit = gm_unit
	_on_hit_sun = on_hit_sun

func spawn():
	var a: Node2D = _asteroid_script.new()
	a.sun_mass = sun_mass
	a.gm_unit = _gm_unit
	a.collided_with_sun.connect(_on_asteroid_collided.bind(a))
	a.spawn()
	add_child(a)
	_asteroids.append(a)

func _on_asteroid_collided(ast: Node2D):
	_on_hit_sun.call(ast)

func set_planet_data(data: Array[Dictionary]):
	_planet_data = data

func _process(delta):
	for i in range(_asteroids.size() - 1, -1, -1):
		var a := _asteroids[i] as Node2D
		if not a.is_alive():
			a.queue_free()
			_asteroids.remove_at(i)
		else:
			a.sun_mass = sun_mass
			a.set_planet_data(_planet_data)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		spawn()
		_spawn_timer = randf_range(35.0, 55.0)
