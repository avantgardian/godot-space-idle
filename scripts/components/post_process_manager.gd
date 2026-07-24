class_name PostProcessManager
extends Node

var _mat: ShaderMaterial
var _ca_impact: float = 0.0
var _bloom_intensity: float = 0.7

func _ready():
	var pp_layer := CanvasLayer.new()
	pp_layer.name = "PostProcessLayer"
	pp_layer.layer = 1
	add_child(pp_layer)

	var cr := ColorRect.new()
	cr.name = "PostProcess"
	cr.anchor_left = 0.0
	cr.anchor_top = 0.0
	cr.anchor_right = 1.0
	cr.anchor_bottom = 1.0
	cr.color = Color(1, 1, 1, 1)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pp_layer.add_child(cr)

	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/world/post_process.gdshader")
	cr.material = _mat
	_mat.set_shader_parameter("u_bloom_intensity", _bloom_intensity)

func trigger():
	_ca_impact = min(_ca_impact + 0.008, 0.015)
	get_parent().get_node("Camera2D").trigger_shake(12.5)

func set_bloom_intensity(value: float) -> void:
	_bloom_intensity = clamp(value, 0.0, 2.0)
	if _mat:
		_mat.set_shader_parameter("u_bloom_intensity", _bloom_intensity)

func get_bloom_intensity() -> float:
	return _bloom_intensity

func _process(delta):
	if _ca_impact > 0.0:
		_ca_impact = max(_ca_impact - 0.02 * delta, 0.0)
		if _mat:
			_mat.set_shader_parameter("u_ca_impact", _ca_impact)