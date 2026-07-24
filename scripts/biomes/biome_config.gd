class_name BiomeConfig
extends Resource

func get_shader() -> Shader:
	push_error("BiomeConfig.get_shader() not implemented")
	return null

func get_texture_size() -> int:
	return 32

func apply_to_shader(_mat: ShaderMaterial) -> void:
	pass

func seed_features(_seed_val: int) -> void:
	pass

func sync_features(_mat: ShaderMaterial) -> void:
	pass
