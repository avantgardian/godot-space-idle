class_name PostProcessManager
extends Node

const _CB_SHADER := preload("res://shaders/world/cb_correct.gdshader")

var _mat: ShaderMaterial
var _cb_mat: ShaderMaterial
var _cb_rect: ColorRect
var _ca_impact: float = 0.0
var _bloom_intensity: float = 0.7
var _screen_shake_enabled: bool = true
var _colorblind_mode: int = 0


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

	_cb_rect = ColorRect.new()
	_cb_rect.name = "ColorblindLayer"
	_cb_rect.anchor_left = 0.0
	_cb_rect.anchor_top = 0.0
	_cb_rect.anchor_right = 1.0
	_cb_rect.anchor_bottom = 1.0
	_cb_rect.color = Color(1, 1, 1, 1)
	_cb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cb_rect.visible = false
	pp_layer.add_child(_cb_rect)

	_cb_mat = ShaderMaterial.new()
	_cb_mat.shader = _CB_SHADER
	_cb_mat.set_shader_parameter("u_mode", 0)
	_cb_rect.material = _cb_mat


func trigger():
	_ca_impact = min(_ca_impact + 0.008, 0.015)
	if _screen_shake_enabled:
		get_parent().get_node("Camera2D").trigger_shake(12.5)


func set_bloom_intensity(value: float) -> void:
	_bloom_intensity = clamp(value, 0.0, 2.0)
	if _mat:
		_mat.set_shader_parameter("u_bloom_intensity", _bloom_intensity)


func set_screen_shake_enabled(enabled: bool) -> void:
	_screen_shake_enabled = enabled


func set_colorblind_mode(mode: int) -> void:
	_colorblind_mode = mode
	if _cb_mat:
		_cb_mat.set_shader_parameter("u_mode", mode)
	if _cb_rect:
		_cb_rect.visible = mode > 0


func get_bloom_intensity() -> float:
	return _bloom_intensity


func _process(delta):
	if _ca_impact > 0.0:
		_ca_impact = max(_ca_impact - 0.02 * delta, 0.0)
		if _mat:
			_mat.set_shader_parameter("u_ca_impact", _ca_impact)
