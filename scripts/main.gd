extends Node2D

@export var star_seed: int = 42

const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

var sun_mass: float = 1.0
var _mass_label: Label
var _planet_data: Array[Node2D]
var _collision_mgr: RefCounted
var _planet_popup: Panel
const _PLANET_POPUP := preload("res://scripts/planet_popup.gd")
const _COLLISION_MGR := preload("res://scripts/collision_manager.gd")
const _POST_PROCESS := preload("res://scripts/post_process_manager.gd")
const _ASTEROID_SPAWNER := preload("res://scripts/asteroid_spawner.gd")
const _ASTEROID_SCRIPT := preload("res://scripts/asteroid.gd")
const _ORBITAL_BODY := preload("res://scripts/orbital_body.gd")
const FONT_MONO := preload("res://resources/fonts/ShareTechMono-Regular.ttf")
func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	$StarField.generate(star_seed, $Camera2D.min_zoom)
	$Sun.generate()
	_mass_label = $UI/MassLabel as Label
	var game_theme := load("res://resources/game_theme.tres") as Theme
	$UI/EventLog/EventLogPanel.theme = game_theme
	$UI/PauseButton.theme = game_theme
	_mass_label.theme = game_theme
	_mass_label.add_theme_font_override("font", FONT_MONO)
	($UI as CanvasLayer).layer = 2
	var pm := _POST_PROCESS.new()
	pm.name = "PostProcessManager"
	add_child(pm)
	var spawner := _ASTEROID_SPAWNER.new()
	spawner.name = "AsteroidSpawner"
	spawner.init(_ASTEROID_SCRIPT, $Mercury._initial_gm(), _on_asteroid_collided)
	add_child(spawner)
	_planet_data = [
		$Mercury,
		$Venus,
		$Earth,
		$Mars,
		$Jupiter,
		$Saturn,
		$Uranus,
		$Neptune,
	]
	for planet in _planet_data:
		planet.collided_with_sun.connect(_on_planet_collided.bind(planet))
		planet.setup_trail(planet.trail_color0, planet.trail_color1)
	_collision_mgr = _COLLISION_MGR.new(_planet_data, _ASTEROID_SCRIPT, $ImpactFX, $UI/EventLog, _find_planet_idx, pm.trigger)

func _show_planet_popup(planet_node: Node2D):
	_close_planet_popup()
	var idx := _find_planet_idx(planet_node)
	if idx < 0:
		return
	var popup := _PLANET_POPUP.new()
	popup.show_for_planet(planet_node, $Camera2D)
	$UI.add_child(popup)
	_planet_popup = popup

func _close_planet_popup():
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	_planet_popup.close()
	_planet_popup = null

func _process(_delta):
	$Sun.mass = sun_mass

	for planet in _planet_data:
		planet.sun_mass = sun_mass

	$AsteroidSpawner.sun_mass = sun_mass
	_collision_mgr.check_collisions($AsteroidSpawner._asteroids)

	var planet_data: Array[Dictionary] = []
	for planet in _planet_data:
		if not planet.is_dead():
			planet_data.append({ pos = planet.position, mass = planet.mass })
	$AsteroidSpawner.set_planet_data(planet_data)

	if _mass_label:
		_mass_label.text = "Msun = %.7f" % sun_mass

	if _planet_popup and not $Camera2D.is_following():
		_close_planet_popup()

	$StarField.update_parallax($Camera2D.position, $Camera2D.zoom.x)
	$StarField.set_blur($Camera2D.get_blur_amount())

func _check_planet_click(screen_pos: Vector2) -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for planet in _planet_data:
		if planet.is_dead():
			continue
		var planet_screen: Vector2 = $Camera2D.get_canvas_transform() * planet.position
		var d := planet_screen.distance_to(screen_pos)
		var hit_r: float = max(planet.collision_radius * $Camera2D.zoom.x, 12.0)
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

func _on_asteroid_collided(ast: Node2D):
	_on_body_hit_sun(ast.mass, 0.2, Color(1, 0.7, 0.3, 0.3), 1.5, 24, 0.4, "Asteroid collided with the Sun")

func _on_body_hit_sun(mass: float, flash: float, ring_color: Color, ring_width: float, ring_segments: int, ring_timer: float, message: String):
	sun_mass += mass
	$Sun.flash(flash)
	$ImpactFX.spawn_ring(ring_color, ring_width, ring_segments, ring_timer)
	$PostProcessManager.trigger()
	$UI/EventLog.log_message(message)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = $Camera2D.get_canvas_transform() * $Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.button_index == MOUSE_BUTTON_LEFT and on_sun:
			sun_mass += 0.1
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			var clicked := _check_planet_click(event.position)
			if clicked:
				$Camera2D.follow_node(clicked)
				_show_planet_popup(clicked)
				return

		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			$Camera2D.start_drag(event.position)
			_close_planet_popup()

	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			$Camera2D.end_drag()

	if event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
		$Camera2D.update_drag(event.position)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL:
			$Camera2D.zoom_in()
		elif event.keycode == KEY_MINUS:
			$Camera2D.zoom_out()
		elif event.keycode == KEY_L:
			$AsteroidSpawner.spawn()
