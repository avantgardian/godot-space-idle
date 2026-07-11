extends "res://scripts/orbital_body.gd"
const _TEX := preload("res://scripts/texture_utils.gd")
var _sprite: Sprite2D

func _ready():
	orbit_radius = 950.0
	orbit_period = 123.0
	start_angle = 4.0
	mass = 0.107
	collision_radius = 13.0
	_trail_max = 1500
	_generate_texture()
	_reset()

func _generate_texture():
	_sprite = Sprite2D.new()
	_sprite.texture = _TEX.make_circle_texture(26, func(t, _x, _y):
		var b: float = 0.6 + 0.4 * (1.0 - t)
		var alpha := 1.0
		if t > 0.85:
			alpha = 1.0 - (t - 0.85) / 0.15
		return Color(0.75 * b, 0.35 * b, 0.15 * b, alpha)
	)
	_sprite.centered = true
	add_child(_sprite)
