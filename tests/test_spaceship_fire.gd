extends GutTest

const SHIP := preload("res://scripts/components/spaceship.gd")
const ROCKET := preload("res://scripts/components/rocket.gd")


func _make_ship() -> Node2D:
	var s: Node2D = autofree(SHIP.new())
	add_child(s)
	s.init(Vector2(100, 0))
	return s


func _make_target() -> Node2D:
	var t := Node2D.new()
	t.name = "Target"
	add_child(t)
	return t


func test_try_fire_returns_rocket_when_ready():
	var s: Node2D = _make_ship()
	var target: Node2D = _make_target()
	var r: Node2D = s.try_fire(target)
	assert_not_null(r, "rocket returned when ship is ready")
	assert_true(r.is_alive(), "fired rocket is alive")


func test_try_fire_blocked_while_in_flight():
	var s: Node2D = _make_ship()
	var target: Node2D = _make_target()
	var r1: Node2D = s.try_fire(target)
	assert_not_null(r1, "first rocket fired")
	var r2: Node2D = s.try_fire(target)
	assert_null(r2, "second rocket blocked while first is in flight")


func test_try_fire_allowed_after_resolved():
	var s: Node2D = _make_ship()
	var target: Node2D = _make_target()
	var r1: Node2D = s.try_fire(target)
	assert_not_null(r1, "first rocket fired")
	r1.disable(ROCKET.Resolution.HIT_TARGET)
	var r2: Node2D = s.try_fire(target)
	assert_not_null(r2, "ship can fire again after rocket resolves")
	assert_ne(r1, r2, "second rocket is a new instance")


func test_try_fire_blocked_when_dead():
	var s: Node2D = _make_ship()
	var target: Node2D = _make_target()
	s.disable()
	var r: Node2D = s.try_fire(target)
	assert_null(r, "dead ship cannot fire")


func test_in_flight_gate_survives_ship_death():
	var s: Node2D = _make_ship()
	var target: Node2D = _make_target()
	var r1: Node2D = s.try_fire(target)
	assert_not_null(r1, "first rocket fired")
	s.disable()
	r1.disable(ROCKET.Resolution.LOST)
	var r2: Node2D = s.try_fire(target)
	assert_null(r2, "dead ship stays unable to fire after rocket resolves")
