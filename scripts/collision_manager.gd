class_name CollisionManager
extends RefCounted

var _planet_data: Array[Dictionary]
var _asteroid_script: GDScript
var _impact_fx: Node
var _event_log: Node
var _find_planet_idx: Callable
var _trigger_impact: Callable

func _init(planet_data: Array[Dictionary], asteroid_script: GDScript, impact_fx: Node, event_log: Node, find_planet_idx: Callable, trigger_impact: Callable):
	_planet_data = planet_data
	_asteroid_script = asteroid_script
	_impact_fx = impact_fx
	_event_log = event_log
	_find_planet_idx = find_planet_idx
	_trigger_impact = trigger_impact

func check_collisions(asteroids: Array):
	var all_bodies: Array[Node2D] = []

	for p in _planet_data:
		if not p.node.is_dead():
			all_bodies.append(p.node)

	for a in asteroids:
		if _is_alive(a):
			all_bodies.append(a)

	for i in all_bodies.size():
		for j in range(i + 1, all_bodies.size()):
			var a := all_bodies[i]
			var b := all_bodies[j]
			if not _is_alive(a) or not _is_alive(b):
				continue
			var dist := a.position.distance_to(b.position)
			if dist < a.collision_radius + b.collision_radius:
				_resolve(a, b)

func _is_alive(body: Node2D) -> bool:
	if body.get_script() == _asteroid_script:
		return body.is_alive()
	return not body.is_dead()

func _disable(body: Node2D):
	body.disable()

func _body_name(body: Node2D) -> String:
	var idx: int = _find_planet_idx.call(body)
	return _planet_data[idx].node.planet_name if idx >= 0 else "Asteroid"

func _collision_msg(victim: Node2D, absorber: Node2D) -> String:
	if _find_planet_idx.call(victim) < 0 or _find_planet_idx.call(absorber) < 0:
		return _body_name(victim) + " collided with " + _body_name(absorber)
	return _body_name(victim) + " was destroyed by " + _body_name(absorber)

func _resolve(a: Node2D, b: Node2D):
	var contact_r: float = a.collision_radius + b.collision_radius
	if a.mass >= b.mass:
		var total: float = a.mass + b.mass
		a.set_vel((a.get_vel() * a.mass + b.get_vel() * b.mass) / total)
		a.mass = total
		var b_idx: int = _find_planet_idx.call(b)
		if b_idx >= 0:
			_planet_data[b_idx].destroyed_by = a.planet_name
		_disable(b)
		_impact_fx.spawn_glow(a.position.lerp(b.position, 0.5), b.mass, contact_r)
		_trigger_impact.call()
		_event_log.log_message(_collision_msg(b, a))
	else:
		var total: float = a.mass + b.mass
		b.set_vel((b.get_vel() * b.mass + a.get_vel() * a.mass) / total)
		b.mass = total
		var a_idx: int = _find_planet_idx.call(a)
		if a_idx >= 0:
			_planet_data[a_idx].destroyed_by = b.planet_name
		_disable(a)
		_impact_fx.spawn_glow(a.position.lerp(b.position, 0.5), a.mass, contact_r)
		_trigger_impact.call()
		_event_log.log_message(_collision_msg(a, b))
