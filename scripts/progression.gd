extends Node2D

@export var star_seed: int = 42

const BG_COLOR := Color(0x0a / 255.0, 0x0a / 255.0, 0x1a / 255.0)

var sun_mass: float = 1.0
var _mass_label: Label

func _ready():
	RenderingServer.set_default_clear_color(BG_COLOR)
	$StarField.generate(star_seed, $Camera2D.min_zoom)
	$Sun.generate()
	_mass_label = $UI/MassLabel as Label
	($UI as CanvasLayer).layer = 2

func _process(_delta):
	$Sun.mass = sun_mass

	if _mass_label:
		_mass_label.text = "M☉ = %.7f" % sun_mass

	$StarField.update_parallax($Camera2D.position, $Camera2D.zoom.x)
	$StarField.set_blur($Camera2D.get_blur_amount())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var sun_screen: Vector2 = $Camera2D.get_canvas_transform() * $Sun.position
		var on_sun: bool = sun_screen.distance_to(event.position) < 60.0
		if event.button_index == MOUSE_BUTTON_LEFT and on_sun:
			sun_mass += 0.1
			return

		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			$Camera2D.start_drag(event.position)

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
