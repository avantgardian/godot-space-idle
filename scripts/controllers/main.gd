extends "res://scripts/controllers/game_controller.gd"

const _PLANET_POPUP: GDScript = preload("res://scripts/ui/planet_popup.gd")
const _RING_SYSTEM: GDScript = preload("res://scripts/components/ring_system.gd")

var _planet_data: Array[Node2D]
var _planet_popup: PlanetPopup
var _planet_data_cache: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	@warning_ignore("unsafe_method_access")
	_sun.generate()
	@warning_ignore("unsafe_cast")
	_planet_data = [
		%Mercury as OrbitalBody,
		%Venus as OrbitalBody,
		%Earth as OrbitalBody,
		%Mars as OrbitalBody,
		%Jupiter as OrbitalBody,
		%Saturn as OrbitalBody,
		%Uranus as OrbitalBody,
		%Neptune as OrbitalBody,
	]
	for planet: Node2D in _planet_data:
		@warning_ignore("unsafe_method_access", "unsafe_property_access")
		planet.collided_with_sun.connect(_on_planet_collided)
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		planet.setup_trail(planet.planet_color)
		_planet_data_cache.append({"pos": Vector2.ZERO, "mass": 0.0})
	var ring: RingSystemComponent = _RING_SYSTEM.new()
	ring.ring_inner = 0.40
	ring.ring_outer = 0.68
	ring.cassini = 0.49
	ring.cassini_width = 0.025
	ring.encke = 0.55
	ring.encke_width = 0.006
	ring.shadow_strength = 0.4
	@warning_ignore("unsafe_cast")
	(%Saturn as Node).add_child(ring)
	_collision_mgr = _COLLISION_MGR.new(
		_planet_data, _ASTEROID_SCRIPT, _impact_fx, _event_log, _find_planet_idx, _post_fx.trigger
	)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	for planet: Node2D in _planet_data:
		@warning_ignore("unsafe_property_access")
		planet.sun_mass = sun_mass
	for i: int in _planet_data.size():
		var planet: Node2D = _planet_data[i]
		var cache: Dictionary = _planet_data_cache[i]
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		cache.pos = planet.position
		@warning_ignore("unsafe_property_access", "unsafe_method_access")
		cache.mass = planet.mass if not planet.is_dead() else 0.0
	_spawner.set_planet_data(_planet_data_cache)
	if _planet_popup and not _camera.is_following():
		_close_planet_popup()


func _get_asteroid_gm() -> float:
	@warning_ignore("unsafe_method_access")
	return (%Mercury as OrbitalBody).get_gm()


func _get_click_target(screen_pos: Vector2) -> Node2D:
	return _check_planet_click(screen_pos)


func _on_select_target(target: Node2D) -> void:
	super._on_select_target(target)
	_show_planet_popup(target)


func _on_drag_pressed(pos: Vector2) -> void:
	super._on_drag_pressed(pos)
	_close_planet_popup()


func _check_planet_click(screen_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = INF
	var canvas: Transform2D = _camera.get_canvas_transform()
	var zoom: float = _camera.zoom.x
	for planet: Node2D in _planet_data:
		@warning_ignore("unsafe_method_access", "unsafe_property_access", "unsafe_call_argument")
		if planet.is_dead():
			continue
		var planet_screen: Vector2 = canvas * planet.position
		@warning_ignore("unsafe_property_access")
		var coll_r: float = planet.collision_radius
		var d: float = planet_screen.distance_to(screen_pos)
		var hit_r: float = max(coll_r * zoom, 12.0)
		if d < hit_r and d < closest_dist:
			closest = planet
			closest_dist = d
	return closest


func _find_planet_idx(node: Node2D) -> int:
	for i: int in _planet_data.size():
		if _planet_data[i] == node:
			return i
	return -1


func _on_planet_collided(body: Node2D) -> void:
	@warning_ignore("unsafe_property_access", "unsafe_call_argument")
	_on_body_hit_sun(body.mass, body.collision_profile, body.planet_name)


func _show_planet_popup(planet_node: Node2D) -> void:
	_close_planet_popup()
	_close_sun_popup()
	var idx: int = _find_planet_idx(planet_node)
	if idx < 0:
		return
	var popup: PlanetPopup = _PLANET_POPUP.new()
	popup.show_for_planet(planet_node, _camera)
	popup.reduced_motion = _settings.reduced_motion
	_ui.add_child(popup)
	_planet_popup = popup


func _close_planet_popup() -> void:
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	_planet_popup.close()
	_planet_popup = null
