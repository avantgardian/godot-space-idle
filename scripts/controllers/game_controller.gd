extends Node2D

const BG_COLOR: Color = Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)
const PAL: GDScript = preload("res://scripts/util/tron_palette.gd")
const _SUN_POPUP: GDScript = preload("res://scripts/ui/sun_popup.gd")
const _ASTEROID_SPAWNER: GDScript = preload("res://scripts/components/asteroid_spawner.gd")
const _ASTEROID_SCRIPT: GDScript = preload("res://scripts/bodies/asteroid.gd")
const _COLLISION_MGR: GDScript = preload("res://scripts/controllers/collision_manager.gd")
const _ASTEROID_COLLISION: CollisionProfile = preload("res://resources/collision/asteroid.tres")
const _POST_PROCESS: GDScript = preload("res://scripts/components/post_process_manager.gd")
const _SETTINGS: GDScript = preload("res://scripts/util/settings_manager.gd")
const _PAUSE_MENU: GDScript = preload("res://scripts/ui/pause_menu.gd")

@export var star_seed: int = 42
@export var asteroid_collision_profile: CollisionProfile = _ASTEROID_COLLISION

var sun_mass: float = 1.0
var _paused: bool = false
var _pause_menu: PauseMenu
var _collision_mgr: CollisionManager
var _sun_popup: SunPopup
var _settings: SettingsManager
var _spawner: AsteroidSpawner
var _post_fx: PostProcessManager

@onready var _sun: Sprite2D = %Sun
@onready var _camera: CameraController = %Camera2D
@onready var _star_field: Node2D = %StarField
@onready var _impact_fx: ImpactFX = %ImpactFX
@onready var _event_log: EventLog = %EventLog
@onready var _event_log_panel: Panel = %EventLogPanel
@onready var _pause_btn: Button = %PauseButton
@onready var _ui: CanvasLayer = %UI


func _ready() -> void:
	RenderingServer.set_default_clear_color(BG_COLOR)
	@warning_ignore("unsafe_method_access")
	_star_field.generate(star_seed, _camera.min_zoom)
	_apply_theme()
	_add_post_process()
	@warning_ignore("unsafe_cast")
	_post_fx = %PostProcessManager as PostProcessManager
	_add_asteroid_spawner()
	@warning_ignore("unsafe_cast")
	_spawner = %AsteroidSpawner as AsteroidSpawner
	_ui.layer = 2
	_load_settings()


func _apply_theme() -> void:
	var game_theme: Theme = load("res://resources/game_theme.tres") as Theme
	_event_log_panel.theme = game_theme
	_pause_btn.theme = game_theme
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	_pause_btn.pause_toggled.connect(_on_pause_toggled)


func _add_post_process() -> void:
	var pm: PostProcessManager = _POST_PROCESS.new()
	pm.name = "PostProcessManager"
	add_child(pm)
	pm.owner = self
	pm.unique_name_in_owner = true


func _add_asteroid_spawner() -> void:
	var spawner: AsteroidSpawner = _ASTEROID_SPAWNER.new()
	spawner.name = "AsteroidSpawner"
	spawner.init(
		_ASTEROID_SCRIPT, _get_asteroid_gm(), _on_asteroid_collided.bind(asteroid_collision_profile)
	)
	add_child(spawner)
	spawner.owner = self
	spawner.unique_name_in_owner = true


func _get_asteroid_gm() -> float:
	return 0.0


func _physics_process(_delta: float) -> void:
	@warning_ignore("unsafe_property_access")
	_sun.mass = sun_mass
	_spawner.sun_mass = sun_mass
	if _collision_mgr:
		@warning_ignore("unsafe_property_access")
		_collision_mgr.check_collisions(_spawner._asteroids)
	@warning_ignore("unsafe_method_access")
	_star_field.update_parallax(_camera.position, _camera.zoom.x)
	if _star_field.has_method("set_focus"):
		@warning_ignore("unsafe_method_access")
		_star_field.set_focus(_camera.get_focus_t())
	else:
		@warning_ignore("unsafe_method_access")
		_star_field.set_blur(_camera.get_blur_amount())


func _load_settings() -> void:
	_settings = _SETTINGS.new()
	_post_fx.set_screen_shake_enabled(_settings.screen_shake)
	_post_fx.set_colorblind_mode(_settings.colorblind_mode)
	_camera.set_screen_shake_enabled(_settings.screen_shake)
	@warning_ignore("unsafe_method_access")
	_sun.set_animations_enabled(not _settings.reduced_motion)
	if _star_field and _star_field.has_method("set_reduced_motion"):
		@warning_ignore("unsafe_method_access")
		_star_field.set_reduced_motion(_settings.reduced_motion)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		@warning_ignore("unsafe_property_access")
		var mb_pressed: bool = event.pressed
		@warning_ignore("unsafe_property_access")
		var mb_pos: Vector2 = event.position
		if mb_pressed:
			if event.is_action_pressed("select"):
				var sun_screen: Vector2 = _camera.get_canvas_transform() * _sun.position
				var on_sun: bool = sun_screen.distance_to(mb_pos) < 60.0
				if on_sun:
					_on_sun_clicked()
					return

				var clicked: Node2D = _get_click_target(mb_pos)
				if clicked:
					_close_sun_popup()
					_on_select_target(clicked)
					return

				_close_sun_popup()

			if event.is_action_pressed("drag"):
				_close_sun_popup()
				@warning_ignore("unsafe_call_argument")
				_on_drag_pressed(mb_pos)

	if event is InputEventMouseButton:
		@warning_ignore("unsafe_property_access")
		var mb_pressed2: bool = event.pressed
		if not mb_pressed2:
			if event.is_action_released("drag"):
				_camera.end_drag()

	if event is InputEventMouseMotion:
		@warning_ignore("unsafe_property_access")
		var mm_pos: Vector2 = event.position
		if Input.is_action_pressed("drag"):
			_camera.update_drag(mm_pos)

	if event is InputEventKey:
		@warning_ignore("unsafe_property_access")
		var key_pressed: bool = event.pressed
		@warning_ignore("unsafe_property_access")
		var key_echo: bool = event.echo
		if key_pressed and not key_echo:
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


func _on_select_target(target: Node2D) -> void:
	_camera.follow_node(target)


func _on_sun_clicked() -> void:
	_camera.unfollow()
	_show_sun_popup()


func _show_sun_popup() -> void:
	_close_sun_popup()
	var popup: SunPopup = _SUN_POPUP.new()
	popup.show_for_sun(self, _camera, _sun, _get_star_type())
	popup.reduced_motion = _settings.reduced_motion
	_ui.add_child(popup)
	_sun_popup = popup


func _close_sun_popup() -> void:
	if not _sun_popup or not is_instance_valid(_sun_popup):
		_sun_popup = null
		return
	_sun_popup.close()
	_sun_popup = null


func _get_star_type() -> String:
	return ""


func _on_drag_pressed(pos: Vector2) -> void:
	_camera.start_drag(pos)


func _on_key_pressed(_event: InputEvent) -> void:
	pass


func _on_asteroid_collided(ast: Node2D, profile: CollisionProfile) -> void:
	@warning_ignore("unsafe_property_access", "unsafe_call_argument")
	_on_body_hit_sun(ast.mass, profile, "Asteroid")


func _on_body_hit_sun(mass: float, profile: CollisionProfile, body_name: String) -> void:
	sun_mass += mass
	@warning_ignore("unsafe_method_access")
	_sun.flash(profile.flash)
	_impact_fx.spawn_ring(
		profile.ring_color, profile.ring_width, profile.ring_segments, profile.ring_timer
	)
	_post_fx.trigger()
	_event_log.log_message(body_name + " collided with the Sun")


func _on_pause_toggled() -> void:
	_toggle_pause()


func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	@warning_ignore("unsafe_method_access")
	_pause_btn.set_pause_state(_paused)
	if _paused:
		_show_pause_menu()
	else:
		_hide_pause_menu()


func _show_pause_menu() -> void:
	@warning_ignore("unsafe_cast")
	_pause_menu = _PAUSE_MENU.new() as PauseMenu
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	_pause_menu.resume_pressed.connect(_toggle_pause)
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	_pause_menu.exit_to_menu_pressed.connect(_on_exit_to_menu)
	@warning_ignore("unsafe_call_argument")
	_ui.add_child(_pause_menu)


func _hide_pause_menu() -> void:
	if _pause_menu and is_instance_valid(_pause_menu):
		@warning_ignore("unsafe_method_access")
		_pause_menu.close()
	_pause_menu = null


func _on_exit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
