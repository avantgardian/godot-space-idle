class_name CollisionManager
extends RefCounted

var _planet_data: Array[Node2D]
var _asteroid_script: GDScript
var _impact_fx: Node
var _event_log: Node
var _find_planet_idx: Callable
var _trigger_impact: Callable


func _init(
	planet_data: Array[Node2D],
	asteroid_script: GDScript,
	impact_fx: Node,
	event_log: Node,
	find_planet_idx: Callable,
	trigger_impact: Callable
) -> void:
	_planet_data = planet_data
	_asteroid_script = asteroid_script
	_impact_fx = impact_fx
	_event_log = event_log
	_find_planet_idx = find_planet_idx
	_trigger_impact = trigger_impact


func check_collisions(asteroids: Array) -> void:
	var all_bodies: Array[Node2D] = []

	for p: Node2D in _planet_data:
		@warning_ignore("unsafe_method_access")
		if not p.is_dead():
			all_bodies.append(p)

	for a: Node2D in asteroids:
		if _is_alive(a):
			all_bodies.append(a)

	for i: int in all_bodies.size():
		for j: int in range(i + 1, all_bodies.size()):
			var a: Node2D = all_bodies[i]
			var b: Node2D = all_bodies[j]
			if not _is_alive(a) or not _is_alive(b):
				continue
			@warning_ignore("unsafe_property_access")
			var sum_r: float = a.collision_radius + b.collision_radius
			if a.position.distance_squared_to(b.position) < sum_r * sum_r:
				_resolve(a, b)


func _is_alive(body: Node2D) -> bool:
	if body.get_script() == _asteroid_script:
		@warning_ignore("unsafe_method_access")
		return body.is_alive()
	@warning_ignore("unsafe_method_access")
	return not body.is_dead()


func _disable(body: Node2D) -> void:
	@warning_ignore("unsafe_method_access")
	body.disable()


func _body_name(body: Node2D) -> String:
	var idx: int = _find_planet_idx.call(body)
	@warning_ignore("unsafe_property_access")
	return _planet_data[idx].planet_name if idx >= 0 else "Asteroid"


func _collision_msg(victim: Node2D, absorber: Node2D) -> String:
	if _find_planet_idx.call(victim) < 0 or _find_planet_idx.call(absorber) < 0:
		return _body_name(victim) + " collided with " + _body_name(absorber)
	return _body_name(victim) + " was destroyed by " + _body_name(absorber)


func _resolve(a: Node2D, b: Node2D) -> void:
	@warning_ignore("unsafe_property_access")
	var contact_r: float = a.collision_radius + b.collision_radius
	@warning_ignore("unsafe_property_access")
	if a.mass >= b.mass:
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		var total: float = a.mass + b.mass
		@warning_ignore("unsafe_method_access", "unsafe_property_access")
		a.set_vel((a.get_vel() * a.mass + b.get_vel() * b.mass) / total)
		@warning_ignore("unsafe_property_access")
		a.mass = total
		_disable(b)
		@warning_ignore(
			"unsafe_property_access", "unsafe_method_access", "unsafe_call_argument", "unsafe_cast"
		)
		_impact_fx.spawn_glow(a.position.lerp(b.position, 0.5), b.mass as float, contact_r)
		_trigger_impact.call()
		@warning_ignore("unsafe_method_access")
		_event_log.log_message(_collision_msg(b, a))
	else:
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		var total: float = a.mass + b.mass
		@warning_ignore("unsafe_method_access", "unsafe_property_access")
		b.set_vel((b.get_vel() * b.mass + a.get_vel() * a.mass) / total)
		@warning_ignore("unsafe_property_access")
		b.mass = total
		_disable(a)
		@warning_ignore(
			"unsafe_property_access", "unsafe_method_access", "unsafe_call_argument", "unsafe_cast"
		)
		_impact_fx.spawn_glow(a.position.lerp(b.position, 0.5), a.mass as float, contact_r)
		_trigger_impact.call()
		@warning_ignore("unsafe_method_access")
		_event_log.log_message(_collision_msg(a, b))
