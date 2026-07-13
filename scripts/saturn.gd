extends OrbitalBody
var planet_name: String = "Saturn"
var planet_color: Color = Color(0.8, 0.7, 0.4)
@export var trail_color0: Color = Color(0.8, 0.7, 0.4, 0.0)
@export var trail_color1: Color = Color(0.8, 0.7, 0.4, 0.4)
@export var collision_flash: float = 1.8
@export var collision_ring_color: Color = Color(0.8, 0.7, 0.4, 0.8)
@export var collision_ring_width: float = 5.0
@export var collision_ring_segments: int = 88
@export var collision_ring_timer: float = 2.2
var _ring: Sprite2D

func _ready():
	super()
	_generate_ring()

func _process(delta):
	super(delta)
	_ring.rotation += delta * 0.05

func _get_planet_texture_size() -> int:
	return 88

func _get_planet_color(t: float, _x: int, y: int) -> Color:
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
