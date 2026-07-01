extends Node2D

const GM_UNIT: float = 4.0 * PI * PI * 350.0 * 350.0 * 350.0 / (30.0 * 30.0)

var sun_mass: float = 1.0
var _pos: Vector2
var _vel: Vector2
var _trail: PackedVector2Array
var _trail_tick: int = 0
var _alive: bool = false
var _sprite: Sprite2D
var _trail_line: Line2D

signal collided_with_sun

func _ready():
	_generate_texture()
	_trail_line = Line2D.new()
	_trail_line.top_level = true
	_trail_line.width = 1.0
	_trail_line.antialiased = true
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.2, 0.05, 0.0))
	grad.set_color(1, Color(1.0, 0.2, 0.05, 0.5))
	_trail_line.gradient = grad
	add_child(_trail_line)

func _generate_texture():
	var size := 14
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx := size / 2.0
	var cy := size / 2.0
	var max_r := size / 2.0 - 1
	for x in range(size):
		for y in range(size):
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= max_r:
				var noise := rng.randf_range(0.7, 1.0)
				if dist <= max_r * noise:
					var bright := rng.randf_range(0.3, 0.5)
					var c := Color(bright, bright * 0.95, bright * 0.9)
					var alpha := 1.0
					if dist > max_r * noise * 0.7:
						alpha = 1.0 - (dist - max_r * noise * 0.7) / (max_r * noise * 0.3)
					image.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	_sprite = Sprite2D.new()
	_sprite.texture = ImageTexture.create_from_image(image)
	_sprite.centered = true
	add_child(_sprite)

func spawn():
	var spawn_r := randf_range(900.0, 1200.0)
	var entry_angle := randf_range(0.0, TAU)
	_pos = Vector2(cos(entry_angle), sin(entry_angle)) * spawn_r

	var gm := GM_UNIT * sun_mass
	var v_circ := sqrt(gm / spawn_r)
	var radial := -randf_range(20.0, 60.0)
	var tangential := randf_range(0.2, 1.6) * v_circ
	var dir := Vector2(cos(entry_angle), sin(entry_angle))
	var tangent := Vector2(-dir.y, dir.x)
	_vel = dir * radial + tangent * tangential

	position = _pos
	_trail.clear()
	_alive = true
	visible = true

func _process(delta):
	if not _alive:
		return

	var gm := GM_UNIT * sun_mass
	var r2 := _pos.length_squared()
	if r2 < 4.0:
		r2 = 4.0
	var r := sqrt(r2)
	var acc := -gm / r2 * _pos / r
	_vel += acc * delta
	_pos += _vel * delta
	position = _pos

	_sprite.rotation += delta * 1.5

	var sun_r := (128.0 + sqrt(sun_mass) * 8.0) * 0.85
	if r < sun_r:
		_alive = false
		visible = false
		collided_with_sun.emit()
		return

	if r > 4000.0:
		_alive = false
		visible = false
		return

	_trail_tick += 1
	if _trail_tick % 2 == 0:
		_trail.append(position)
		if _trail.size() > 600:
			_trail.remove_at(0)
	_trail_line.points = _trail if _trail.size() >= 2 else PackedVector2Array()

func is_alive() -> bool:
	return _alive
