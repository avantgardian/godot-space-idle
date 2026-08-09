extends GutTest

const SPAWNER := preload("res://scripts/components/asteroid_spawner.gd")
const ASTEROID := preload("res://scripts/bodies/asteroid.gd")


func test_init_stores_params():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.init(ASTEROID, 1.0, func(_ast): pass)
	assert_eq(s._asteroid_script, ASTEROID, "script stored")
	assert_almost_eq(s._gm_unit, 1.0, 0.001, "gm_unit stored")


func test_spawn_creates_asteroid():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 1.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s.spawn()
	assert_eq(s._asteroids.size(), 1, "one asteroid spawned")


func test_spawned_asteroid_inherits_sun_mass():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 5.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s.spawn()
	var a := s._asteroids[0] as Node2D
	assert_almost_eq(a.sun_mass, 5.0, 0.001, "asteroid inherits sun_mass")


func test_process_removes_dead_asteroids():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 1.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s.spawn()
	var a := s._asteroids[0] as Node2D
	# Make the asteroid appear dead
	a._alive = false
	s._process(0.1)
	assert_eq(s._asteroids.size(), 0, "dead asteroid removed")


func test_spawn_timer_resets():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 1.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s._spawn_timer = 0.0
	s._process(0.1)
	assert_gt(s._spawn_timer, 0.0, "spawn timer reset after triggering")


func test_spawn_timer_decrements():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 1.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s._spawn_timer = 10.0
	s._process(2.0)
	assert_almost_eq(s._spawn_timer, 8.0, 0.01, "timer decrements by delta")


func test_planet_data_stored():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.init(ASTEROID, 1.0, func(_ast): pass)
	var data: Array[Dictionary] = [{pos = Vector2.ZERO, mass = 1.0}]
	s.set_planet_data(data)
	assert_eq(s._planet_data, data, "planet_data stored")


func test_process_updates_asteroid_sun_mass():
	var s: Node = autofree(SPAWNER.new())
	add_child(s)
	s.sun_mass = 3.0
	s.init(ASTEROID, 1.0, func(_ast): pass)
	s.spawn()
	s.sun_mass = 7.0
	s._process(0.1)
	var a := s._asteroids[0] as Node2D
	assert_almost_eq(a.sun_mass, 7.0, 0.001, "asteroid sun_mass updated")
