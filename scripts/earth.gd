extends "res://scripts/orbital_body.gd"
const _TEX := preload("res://scripts/texture_utils.gd")
var _sprite: Sprite2D

func _ready():
	orbit_radius = 700.0
	orbit_period = 78.0
	start_angle = 1.0
	mass = 1.0
	collision_radius = 24.0
	_trail_max = 1200
	_generate_texture()
	_reset()

func _generate_texture():
	_sprite = Sprite2D.new()
	_sprite.texture = _TEX.make_circle_texture(48, func(t, _x, _y):
		var b: float = 0.7 + 0.3 * (1.0 - t)
		var alpha := 1.0
		if t > 0.85:
			alpha = 1.0 - (t - 0.85) / 0.15
		if t < 0.3:
			return Color(0.3 * b, 0.6 * b, 0.4 * b, alpha)
		elif t < 0.6:
			return Color(0.4 * b, 0.7 * b, 0.5 * b, alpha)
		else:
			return Color(0.6 * b, 0.8 * b, 0.9 * b, alpha)
	)
	_sprite.centered = true
	add_child(_sprite)
