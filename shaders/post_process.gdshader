shader_type canvas_item;

uniform float u_vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float u_vignette_radius : hint_range(0.0, 1.0) = 0.55;

uniform float u_ca_impact = 0.0;

uniform sampler2D iChannel0 : hint_screen_texture, filter_linear, repeat_disable;

void fragment() {
	vec2 uv = UV;
	vec4 col = texture(iChannel0, uv);

	if (u_ca_impact > 0.0) {
		float r = texture(iChannel0, uv + vec2(u_ca_impact, 0.0)).r;
		float g = texture(iChannel0, uv).g;
		float b = texture(iChannel0, uv + vec2(-u_ca_impact, 0.0)).b;
		col = vec4(r, g, b, col.a);
	}

	float d = distance(uv, vec2(0.5, 0.5)) * 1.414;
	float v = 1.0 - smoothstep(u_vignette_radius, 1.0, d) * u_vignette_intensity;
	col.rgb *= v;

	COLOR = col;
}
