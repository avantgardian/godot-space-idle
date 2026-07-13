extends Node2D

@export var star_seed: int = 42

const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

var sun_mass: float = 1.0
var _mass_label: Label
var _asteroids: Array
var _asteroid_spawn_timer: float = 5.0
var _planet_data: Array[Node2D]
var _collision_mgr: CollisionManager
var _planet_popup: Panel
const _ASTEROID_SCRIPT := preload("res://scripts/asteroid.gd")
const _PLANET_POPUP := preload("res://scripts/planet_popup.gd")
const _COLLISION_MGR := preload("res://scripts/collision_manager.gd")
func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	$StarField.generate(star_seed, $Camera2D.min_zoom)
	$Sun.generate()
	_mass_label = $UI/MassLabel as Label
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
	_collision_mgr = CollisionManager.new(_planet_data, _ASTEROID_SCRIPT, $ImpactFX, $UI/EventLog, _find_planet_idx, _trigger_impact_effects)
	_setup_post_process()

func _setup_post_process():
	var pp_layer := CanvasLayer.new()
	pp_layer.name = "PostProcessLayer"
	pp_layer.layer = 1
	add_child(pp_layer)

	($UI as CanvasLayer).layer = 2

	var cr := ColorRect.new()
	cr.name = "PostProcess"
	cr.anchor_left = 0.0
	cr.anchor_top = 0.0
	cr.anchor_right = 1.0
	cr.anchor_bottom = 1.0
	cr.color = Color(1, 1, 1, 1)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pp_layer.add_child(cr)

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/post_process.gdshader")
	cr.material = mat
	_post_process_mat = mat

func _trigger_impact_effects():
	_ca_impact = min(_ca_impact + 0.008, 0.015)
	$Camera2D.trigger_shake(12.5)

func _show_planet_popup(planet_node: Node2D):
	_close_planet_popup()
	var idx := _find_planet_idx(planet_node)
	if idx < 0:
		return
	var popup := PlanetPopup.new()
	popup.show_for_planet(planet_node, $Camera2D)
	$UI.add_child(popup)
	_planet_popup = popup

func _close_planet_popup():
	if not _planet_popup or not is_instance_valid(_planet_popup):
		_planet_popup = null
		return
	_planet_popup.close()
	_planet_popup = null

var _post_process_mat: ShaderMaterial
var _ca_impact: float = 0.0

func _process(delta):
	$Sun.mass = sun_mass

	for planet in _planet_data:
		planet.sun_mass = sun_mass

	_collision_mgr.check_collisions(_asteroids)

	var planet_data: Array[Dictionary] = []
	for planet in _planet_data:
		if not planet.is_dead():
			planet_data.append({ pos = planet.position, mass = planet.mass })

	for i in range(_asteroids.size() - 1, -1, -1):
		var a := _asteroids[i] as Node2D
		if not a.is_alive():
			a.queue_free()
			_asteroids.remove_at(i)
		else:
			a.sun_mass = sun_mass
			a.set_planet_data(planet_data)

	_asteroid_spawn_timer -= delta
	if _asteroid_spawn_timer <= 0.0 and _asteroids.size() < 3:
		_spawn_asteroid()
		_asteroid_spawn_timer = randf_range(35.0, 55.0)

	if _mass_label:
		_mass_label.text = "M☉ = %.7f" % sun_mass

	if _ca_impact > 0.0:
		_ca_impact = max(_ca_impact - 0.02 * delta, 0.0)
		if _post_process_mat:
			_post_process_mat.set_shader_parameter("u_ca_impact", _ca_impact)

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

func _spawn_asteroid():
	var a := _ASTEROID_SCRIPT.new()
	a.sun_mass = sun_mass
	a.gm_unit = $Mercury._initial_gm()
	a.collided_with_sun.connect(_on_asteroid_collided.bind(a))
	a.spawn()
	add_child(a)
	_asteroids.append(a)

func _on_asteroid_collided(ast: Node2D):
	_on_body_hit_sun(ast.mass, 0.2, Color(1, 0.7, 0.3, 0.3), 1.5, 24, 0.4, "Asteroid collided with the Sun")

func _on_body_hit_sun(mass: float, flash: float, ring_color: Color, ring_width: float, ring_segments: int, ring_timer: float, message: String):
	sun_mass += mass
	$Sun.flash(flash)
	$ImpactFX.spawn_ring(ring_color, ring_width, ring_segments, ring_timer)
	_trigger_impact_effects()
	$UI/EventLog.log_message(message)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = $Camera2D.get_canvas_transform() * $Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.button_index == MOUSE_BUTTON_LEFT and on_sun:
			sun_mass += 0.01
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
			_spawn_asteroid()
