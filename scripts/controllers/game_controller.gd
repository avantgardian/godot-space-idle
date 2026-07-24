extends Node2D

@export var star_seed: int = 42

const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)
const CFG := preload("res://scripts/util/game_config.gd")
const FONT_MONO := preload("res://resources/fonts/ShareTechMono-Regular.ttf")

const _ASTEROID_SPAWNER := preload("res://scripts/components/asteroid_spawner.gd")
const _ASTEROID_SCRIPT := preload("res://scripts/bodies/asteroid.gd")
const _COLLISION_MGR := preload("res://scripts/controllers/collision_manager.gd")
const _POST_PROCESS := preload("res://scripts/components/post_process_manager.gd")

var sun_mass: float = 1.0
var _mass_label: Label
var _collision_mgr: RefCounted
var _last_label_mass: float = -1.0

func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	%StarField.generate(star_seed, %Camera2D.min_zoom)
	_apply_theme()
	_add_post_process()
	_add_asteroid_spawner()
	(%UI as CanvasLayer).layer = 2

func _apply_theme():
	_mass_label = %MassLabel as Label
	var game_theme := load("res://resources/game_theme.tres") as Theme
	%EventLogPanel.theme = game_theme
	%PauseButton.theme = game_theme
	_mass_label.theme = game_theme
	_mass_label.add_theme_font_override("font", FONT_MONO)

func _add_post_process():
	var pm := _POST_PROCESS.new()
	pm.name = "PostProcessManager"
	add_child(pm)
	pm.owner = self
	pm.unique_name_in_owner = true

func _add_asteroid_spawner():
	var spawner := _ASTEROID_SPAWNER.new()
	spawner.name = "AsteroidSpawner"
	spawner.init(_ASTEROID_SCRIPT, _get_asteroid_gm(), _on_asteroid_collided)
	add_child(spawner)
	spawner.owner = self
	spawner.unique_name_in_owner = true

func _get_asteroid_gm() -> float:
	return 0.0

func _process(_delta):
	%Sun.mass = sun_mass
	%AsteroidSpawner.sun_mass = sun_mass
	if _collision_mgr:
		_collision_mgr.check_collisions(%AsteroidSpawner._asteroids)
	_update_mass_label()
	%StarField.update_parallax(%Camera2D.position, %Camera2D.zoom.x)
	%StarField.set_blur(%Camera2D.get_blur_amount())

func _update_mass_label():
	if _mass_label and sun_mass != _last_label_mass:
		_mass_label.text = _format_mass_label(sun_mass)
		_last_label_mass = sun_mass

func _format_mass_label(mass: float) -> String:
	return "Msun = %.7f" % mass

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = %Camera2D.get_canvas_transform() * %Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.is_action_pressed("sun_click") and on_sun:
			sun_mass += CFG.CLICK_MASS_GAIN
			return

		if event.is_action_pressed("select"):
			var clicked := _get_click_target(event.position)
			if clicked:
				_on_select_target(clicked)
				return

		if event.is_action_pressed("drag"):
			_on_drag_pressed(event.position)

	if event is InputEventMouseButton and not event.pressed:
		if event.is_action_released("drag"):
			%Camera2D.end_drag()

	if event is InputEventMouseMotion and Input.is_action_pressed("drag"):
		%Camera2D.update_drag(event.position)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("zoom_in"):
			%Camera2D.zoom_in()
		elif event.is_action_pressed("zoom_out"):
			%Camera2D.zoom_out()
		elif event.is_action_pressed("spawn_asteroid"):
			%AsteroidSpawner.spawn()
		_on_key_pressed(event)

func _get_click_target(_screen_pos: Vector2) -> Node2D:
	return null

func _on_select_target(target: Node2D):
	%Camera2D.follow_node(target)

func _on_drag_pressed(pos: Vector2):
	%Camera2D.start_drag(pos)

func _on_key_pressed(_event):
	pass

func _on_asteroid_collided(ast: Node2D):
	_on_body_hit_sun(ast.mass, 0.2, Color(1, 0.7, 0.3, 0.3), 1.5, 24, 0.4, "Asteroid collided with the Sun")

func _on_body_hit_sun(mass: float, flash: float, ring_color: Color, ring_width: float, ring_segments: int, ring_timer: float, message: String):
	sun_mass += mass
	%Sun.flash(flash)
	%ImpactFX.spawn_ring(ring_color, ring_width, ring_segments, ring_timer)
	%PostProcessManager.trigger()
	%EventLog.log_message(message)
