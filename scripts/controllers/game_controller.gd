extends Node2D

@export var star_seed: int = 42

const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)
const PAL := preload("res://scripts/util/tron_palette.gd")
const _SUN_POPUP := preload("res://scripts/ui/sun_popup.gd")
const _ASTEROID_SPAWNER := preload("res://scripts/components/asteroid_spawner.gd")
const _ASTEROID_SCRIPT := preload("res://scripts/bodies/asteroid.gd")
const _COLLISION_MGR := preload("res://scripts/controllers/collision_manager.gd")
const _POST_PROCESS := preload("res://scripts/components/post_process_manager.gd")
const _SETTINGS := preload("res://scripts/util/settings_manager.gd")
const _PAUSE_MENU := preload("res://scripts/ui/pause_menu.gd")

var sun_mass: float = 1.0
var _paused := false
var _pause_menu: PauseMenu
var _collision_mgr: RefCounted
var _sun_popup: Panel
var _settings: SettingsManager

@onready var _sun: Sprite2D = %Sun
var _spawner: AsteroidSpawner
@onready var _camera: CameraController = %Camera2D
@onready var _star_field: Node2D = %StarField
@onready var _impact_fx: ImpactFX = %ImpactFX
var _post_fx: PostProcessManager
@onready var _event_log: EventLog = %EventLog
@onready var _event_log_panel: Panel = %EventLogPanel
@onready var _pause_btn: Button = %PauseButton
@onready var _ui: CanvasLayer = %UI


func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	_star_field.generate(star_seed, _camera.min_zoom)
	_apply_theme()
	_add_post_process()
	_post_fx = %PostProcessManager
	_add_asteroid_spawner()
	_spawner = %AsteroidSpawner
	_ui.layer = 2
	_load_settings()


func _apply_theme():
	var game_theme := load("res://resources/game_theme.tres") as Theme
	_event_log_panel.theme = game_theme
	_pause_btn.theme = game_theme
	_pause_btn.pause_toggled.connect(_on_pause_toggled)


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


func _physics_process(_delta):
	_sun.mass = sun_mass
	_spawner.sun_mass = sun_mass
	if _collision_mgr:
		_collision_mgr.check_collisions(_spawner._asteroids)
	_star_field.update_parallax(_camera.position, _camera.zoom.x)
	_star_field.set_blur(_camera.get_blur_amount())


func _load_settings():
	_settings = _SETTINGS.new()
	_post_fx.set_screen_shake_enabled(_settings.screen_shake)
	_post_fx.set_colorblind_mode(_settings.colorblind_mode)
	_camera.set_screen_shake_enabled(_settings.screen_shake)
	_sun.set_animations_enabled(not _settings.reduced_motion)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.is_action_pressed("select"):
			var sun_screen: Vector2 = _camera.get_canvas_transform() * _sun.position
			var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
			if on_sun:
				_on_sun_clicked()
				return

			var clicked := _get_click_target(event.position)
			if clicked:
				_close_sun_popup()
				_on_select_target(clicked)
				return

			_close_sun_popup()

		if event.is_action_pressed("drag"):
			_close_sun_popup()
			_on_drag_pressed(event.position)

	if event is InputEventMouseButton and not event.pressed:
		if event.is_action_released("drag"):
			_camera.end_drag()

	if event is InputEventMouseMotion and Input.is_action_pressed("drag"):
		_camera.update_drag(event.position)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel"):
			_toggle_pause()
		elif event.is_action_pressed("zoom_in"):
			_camera.zoom_in()
		elif event.is_action_pressed("zoom_out"):
			_camera.zoom_out()
		elif event.is_action_pressed("spawn_asteroid"):
			_spawner.spawn()
		_on_key_pressed(event)


func _get_click_target(_screen_pos: Vector2) -> Node2D:
	return null


func _on_select_target(target: Node2D):
	_camera.follow_node(target)


func _on_sun_clicked():
	_camera.unfollow()
	_show_sun_popup()


func _show_sun_popup():
	_close_sun_popup()
	var popup := _SUN_POPUP.new()
	popup.show_for_sun(self, _camera, _sun, _get_star_type())
	popup.reduced_motion = _settings.reduced_motion
	_ui.add_child(popup)
	_sun_popup = popup


func _close_sun_popup():
	if not _sun_popup or not is_instance_valid(_sun_popup):
		_sun_popup = null
		return
	_sun_popup.close()
	_sun_popup = null


func _get_star_type() -> String:
	return ""


func _on_drag_pressed(pos: Vector2):
	_camera.start_drag(pos)


func _on_key_pressed(_event):
	pass


func _on_asteroid_collided(ast: Node2D):
	_on_body_hit_sun(ast.mass, 0.2, PAL.ACCENT, 1.5, 24, 0.4, "Asteroid collided with the Sun")


func _on_body_hit_sun(
	mass: float,
	flash: float,
	ring_color: Color,
	ring_width: float,
	ring_segments: int,
	ring_timer: float,
	message: String
):
	sun_mass += mass
	_sun.flash(flash)
	_impact_fx.spawn_ring(ring_color, ring_width, ring_segments, ring_timer)
	_post_fx.trigger()
	_event_log.log_message(message)


func _on_pause_toggled():
	_toggle_pause()


func _toggle_pause():
	_paused = not _paused
	get_tree().paused = _paused
	_pause_btn.set_pause_state(_paused)
	if _paused:
		_show_pause_menu()
	else:
		_hide_pause_menu()


func _show_pause_menu():
	_pause_menu = _PAUSE_MENU.new()
	_pause_menu.resume_pressed.connect(_toggle_pause)
	_pause_menu.exit_to_menu_pressed.connect(_on_exit_to_menu)
	_ui.add_child(_pause_menu)


func _hide_pause_menu():
	if _pause_menu and is_instance_valid(_pause_menu):
		_pause_menu.close()
	_pause_menu = null


func _on_exit_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
