extends "res://scripts/controllers/game_controller.gd"

const _PLANET_POPUP := preload("res://scripts/ui/planet_popup.gd")
const _RING_SYSTEM := preload("res://scripts/components/ring_system.gd")

var _planet_data: Array[Node2D]
var _planet_popup: Panel
var _planet_data_cache: Array[Dictionary] = []


func _ready():
	super._ready()
	_sun.generate()
	_planet_data = [
		%Mercury,
		%Venus,
		%Earth,
		%Mars,
		%Jupiter,
		%Saturn,
		%Uranus,
		%Neptune,
	]
	for planet in _planet_data:
		planet.collided_with_sun.connect(_on_planet_collided)
		planet.setup_trail(planet.planet_color)
		_planet_data_cache.append({pos = Vector2.ZERO, mass = 0.0})
	var ring := _RING_SYSTEM.new()
	ring.ring_inner = 0.40
	ring.ring_outer = 0.68
	ring.cassini = 0.49
	ring.cassini_width = 0.025
	ring.encke = 0.55
	ring.encke_width = 0.006
	ring.shadow_strength = 0.4
	%Saturn.add_child(ring)
	_collision_mgr = _COLLISION_MGR.new(
		_planet_data, _ASTEROID_SCRIPT, _impact_fx, _event_log, _find_planet_idx, _post_fx.trigger
	)


func _physics_process(delta):
	super._physics_process(delta)
	for planet in _planet_data:
		planet.sun_mass = sun_mass
	for i in _planet_data.size():
		var planet := _planet_data[i]
		var cache := _planet_data_cache[i]
		cache.pos = planet.position
		cache.mass = planet.mass if not planet.is_dead() else 0.0
	_spawner.set_planet_data(_planet_data_cache)
	if _planet_popup and not _camera.is_following():
		_close_planet_popup()


func _get_asteroid_gm() -> float:
	return %Mercury.get_gm()


func _get_click_target(screen_pos: Vector2) -> Node2D:
	return _check_planet_click(screen_pos)


func _on_select_target(target: Node2D):
	super._on_select_target(target)
	_show_planet_popup(target)


func _on_drag_pressed(pos: Vector2):
	super._on_drag_pressed(pos)
	_close_planet_popup()


func _check_planet_click(screen_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	var canvas: Transform2D = _camera.get_canvas_transform()
	var zoom: float = _camera.zoom.x
	for planet in _planet_data:
		if planet.is_dead():
			continue
		var planet_screen: Vector2 = canvas * planet.position
		var d := planet_screen.distance_to(screen_pos)
		var hit_r: float = max(planet.collision_radius * zoom, 12.0)
		if d < hit_r and d < closest_dist:
			closest = planet
			closest_dist = d
	return closest


func _find_planet_idx(node: Node2D) -> int:
	for i in _planet_data.size():
		if _planet_data[i] == node:
			return i
	return -1


func _on_planet_collided(body: Node2D):
	_on_body_hit_sun(body.mass, body.collision_profile, body.planet_name)


func _show_planet_popup(planet_node: Node2D):
	_close_planet_popup()
	_close_sun_popup()
	var idx := _find_planet_idx(planet_node)
	if idx < 0:
		return
	var popup := _PLANET_POPUP.new()
	popup.show_for_planet(planet_node, _camera)
	popup.reduced_motion = _settings.reduced_motion
	_ui.add_child(popup)
	_planet_popup = popup


func _close_planet_popup():
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	_planet_popup.close()
	_planet_popup = null
