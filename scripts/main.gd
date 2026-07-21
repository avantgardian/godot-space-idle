extends "res://scripts/game_controller.gd"

const _PLANET_POPUP := preload("res://scripts/planet_popup.gd")

var _planet_data: Array[Node2D]
var _planet_popup: Panel
var _planet_data_cache: Array[Dictionary] = []

func _ready():
	super._ready()
	%Sun.generate()
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
		planet.collided_with_sun.connect(_on_planet_collided.bind(planet))
		planet.setup_trail(planet.planet_color)
		_planet_data_cache.append({ pos = Vector2.ZERO, mass = 0.0 })
	_collision_mgr = _COLLISION_MGR.new(_planet_data, _ASTEROID_SCRIPT, %ImpactFX, %EventLog, _find_planet_idx, %PostProcessManager.trigger)

func _process(delta):
	super._process(delta)
	for planet in _planet_data:
		planet.sun_mass = sun_mass
	for i in _planet_data.size():
		var planet := _planet_data[i]
		var cache := _planet_data_cache[i]
		cache.pos = planet.position
		cache.mass = planet.mass if not planet.is_dead() else 0.0
	%AsteroidSpawner.set_planet_data(_planet_data_cache)
	if _planet_popup and not %Camera2D.is_following():
		_close_planet_popup()

func _get_asteroid_gm() -> float:
	return %Mercury.get_gm()

func _format_mass_label(mass: float) -> String:
	return "Msun = %.7f" % mass

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
	var canvas: Transform2D = %Camera2D.get_canvas_transform()
	var zoom: float = %Camera2D.zoom.x
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

func _on_planet_collided(planet: Node2D):
	_on_body_hit_sun(planet.mass, planet.collision_flash, planet.collision_ring_color, planet.collision_ring_width, planet.collision_ring_segments, planet.collision_ring_timer, planet.planet_name + " collided with the Sun")

func _show_planet_popup(planet_node: Node2D):
	_close_planet_popup()
	var idx := _find_planet_idx(planet_node)
	if idx < 0:
		return
	var popup := _PLANET_POPUP.new()
	popup.show_for_planet(planet_node, %Camera2D)
	%UI.add_child(popup)
	_planet_popup = popup

func _close_planet_popup():
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	_planet_popup.close()
	_planet_popup = null
