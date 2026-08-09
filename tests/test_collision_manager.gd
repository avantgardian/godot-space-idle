extends GutTest

const COLLISION_MGR := preload("res://scripts/controllers/collision_manager.gd")
const ORBITAL_BODY := preload("res://scripts/bodies/orbital_body.gd")
const ASTEROID := preload("res://scripts/bodies/asteroid.gd")

const _PLANET_NAMES := ["Mercury", "Venus", "Earth", "Mars"]

var _event_log_msgs: Array[String] = []
var _trigger_count: int = 0


func before_each():
	_event_log_msgs.clear()
	_trigger_count = 0


func _make_event_log() -> Node:
	var n := Node.new()
	var src := """extends Node

func log_message(msg):
	var parent := get_parent()
	parent._event_log_msgs.append(msg)
"""
	var gds := GDScript.new()
	gds.source_code = src
	gds.reload()
	n.set_script(gds)
	return n


func _make_impact_fx() -> Node:
	var n := Node.new()
	var src := """extends Node

func spawn_glow(_pos, _mass, _contact_radius):
	pass
"""
	var gds := GDScript.new()
	gds.source_code = src
	gds.reload()
	n.set_script(gds)
	return n


func _make_planet(idx: int, pos: Vector2) -> Node2D:
	var p: Node2D = autofree(ORBITAL_BODY.new())
	p.planet_name = _PLANET_NAMES[idx]
	p.orbit_radius = 500.0
	p.orbit_period = 48.0
	p.planet_seed = idx + 1
	add_child(p)
	p.mass = 5.0
	p.collision_radius = 20.0
	p._pos = pos
	p._vel = Vector2.ZERO
	p.position = pos
	p._dead = false
	return p


func _find_idx(body: Node2D) -> int:
	if body.get_script() == ASTEROID:
		return -1
	for i in range(_PLANET_NAMES.size()):
		if body.planet_name == _PLANET_NAMES[i]:
			return i
	return -1


func test_init_stores_all_refs():
	var planets: Array[Node2D] = []
	var fx := _make_impact_fx()
	add_child(fx)
	var log := _make_event_log()
	add_child(log)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	assert_eq(mgr._planet_data, planets, "planet_data stored")
	assert_eq(mgr._asteroid_script, ASTEROID, "asteroid_script stored")


func test_planet_absorbs_smaller_planet():
	var p1 := _make_planet(0, Vector2(0, 0))
	p1.mass = 10.0
	p1.collision_radius = 30.0

	var p2 := _make_planet(1, Vector2(10, 0))
	p2.mass = 2.0
	p2.collision_radius = 15.0

	var planets: Array[Node2D] = [p1, p2]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	mgr.check_collisions([])

	assert_almost_eq(p1.mass, 12.0, 0.001, "absorber mass = sum")
	assert_true(p2.is_dead(), "victim marked dead")
	assert_gt(_event_log_msgs.size(), 0, "event logged")


func test_momentum_conservation_two_planets():
	var p1 := _make_planet(0, Vector2(0, 0))
	p1.mass = 10.0
	p1.collision_radius = 30.0
	p1._vel = Vector2(100, 0)

	var p2 := _make_planet(1, Vector2(10, 0))
	p2.mass = 5.0
	p2.collision_radius = 15.0
	p2._vel = Vector2(-40, 0)

	var initial_momentum: Vector2 = p1._vel * p1.mass + p2._vel * p2.mass

	var planets: Array[Node2D] = [p1, p2]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	mgr.check_collisions([])

	var final_momentum: Vector2 = p1._vel * p1.mass
	assert_almost_eq(final_momentum.x, initial_momentum.x, 0.1, "momentum conserved x")
	assert_almost_eq(final_momentum.y, initial_momentum.y, 0.1, "momentum conserved y")


func test_does_not_collide_when_too_far():
	var p1 := _make_planet(0, Vector2(0, 0))
	p1.mass = 10.0
	p1.collision_radius = 30.0

	var p2 := _make_planet(1, Vector2(100, 0))
	p2.mass = 5.0
	p2.collision_radius = 15.0

	var planets: Array[Node2D] = [p1, p2]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	mgr.check_collisions([])

	assert_false(p2.is_dead(), "no collision at distance")
	assert_eq(_event_log_msgs.size(), 0, "no events logged")


func test_dead_planets_skipped():
	var p1 := _make_planet(0, Vector2(0, 0))
	p1.mass = 10.0
	p1.collision_radius = 30.0
	p1._dead = true

	var p2 := _make_planet(1, Vector2(5, 0))
	p2.mass = 5.0
	p2.collision_radius = 15.0

	var planets: Array[Node2D] = [p1, p2]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	mgr.check_collisions([])

	assert_false(p2.is_dead(), "dead planet excluded from collision")


func test_collision_msg_both_planets():
	var p1 := _make_planet(0, Vector2.ZERO)
	var p2 := _make_planet(1, Vector2.ZERO)

	var planets: Array[Node2D] = [p1, p2]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	var msg: String = mgr._collision_msg(p2, p1)
	assert_string_contains(msg, "destroyed", "planet-on-planet says 'destroyed'")


func test_collision_msg_asteroid_planet():
	var a: Node2D = autofree(ASTEROID.new())
	a._asteroid_seed = 42
	add_child(a)
	a._alive = true

	var planet := _make_planet(0, Vector2.ZERO)

	var planets: Array[Node2D] = [planet]
	var log := _make_event_log()
	add_child(log)

	var fx := _make_impact_fx()
	add_child(fx)
	var mgr := COLLISION_MGR.new(planets, ASTEROID, fx, log, _find_idx, func(): pass)
	var msg: String = mgr._collision_msg(a, planet)
	assert_string_contains(msg, "collided", "asteroid-on-planet says 'collided'")
