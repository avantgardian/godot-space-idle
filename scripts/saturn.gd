extends "res://scripts/orbital_body.gd"
const _TEX := preload("res://scripts/texture_utils.gd")
var _sprite: Sprite2D
var _ring: Sprite2D

func _ready():
	orbit_radius = 1800.0
	orbit_period = 269.0
	start_angle = 3.0
	mass = 95.2
	collision_radius = 44.0
	_trail_max = 3000
	_generate_texture()
	_generate_ring()
	_reset()

func _process(delta):
	super(delta)
	_ring.rotation += delta * 0.05

func _generate_texture():
	_sprite = Sprite2D.new()
	_sprite.texture = _TEX.make_circle_texture(88, func(t, _x, y):
		var band: float = sin(float(y) * 0.5) * 0.1
		var b: float = 0.7 + 0.3 * (1.0 - t) + band
		var alpha := 1.0
		if t > 0.85:
			alpha = 1.0 - (t - 0.85) / 0.15
		return Color(
			clampf((0.8 + band) * b, 0, 1),
			clampf((0.7 + band) * b, 0, 1),
			clampf((0.4 + band * 0.5) * b, 0, 1),
			alpha
		)
	)
	_sprite.centered = true
	add_child(_sprite)

func _generate_ring():
	var size := 160
	var inner_r := 48.0
	var outer_r := 78.0
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var cx := size / 2.0
	var cy := size / 2.0
	for x in range(size):
		for y in range(size):
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist >= inner_r and dist <= outer_r:
				var t: float = (dist - inner_r) / (outer_r - inner_r)
				var alpha: float = (1.0 - absf(t - 0.5) * 2.0) * 0.5
				var brightness: float = 0.6 + 0.3 * (1.0 - t)
				var r: float = 0.7 * brightness
				var g: float = 0.6 * brightness
				var b: float = 0.3 * brightness
				image.set_pixel(x, y, Color(r, g, b, alpha))
	_ring = Sprite2D.new()
	_ring.texture = ImageTexture.create_from_image(image)
	_ring.centered = true
	_ring.z_index = -1
	add_child(_ring)
