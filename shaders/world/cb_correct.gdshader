shader_type canvas_item;

uniform int u_mode = 0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Daltonize-style colorblind correction matrices.
// 0 = off, 1 = protanopia, 2 = deuteranopia, 3 = tritanopia

const mat3 protanopia_mat = mat3(
	vec3(0.567, 0.433, 0.0),
	vec3(0.558, 0.442, 0.0),
	vec3(0.0, 0.242, 0.758)
);

const mat3 deuteranopia_mat = mat3(
	vec3(0.625, 0.375, 0.0),
	vec3(0.7, 0.3, 0.0),
	vec3(0.0, 0.3, 0.7)
);

const mat3 tritanopia_mat = mat3(
	vec3(0.95, 0.05, 0.0),
	vec3(0.0, 0.433, 0.567),
	vec3(0.0, 0.475, 0.525)
);

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	if (u_mode == 1) {
		color.rgb = color.rgb * protanopia_mat;
	} else if (u_mode == 2) {
		color.rgb = color.rgb * deuteranopia_mat;
	} else if (u_mode == 3) {
		color.rgb = color.rgb * tritanopia_mat;
	}

	COLOR = color;
}
