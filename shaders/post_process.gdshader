shader_type canvas_item;

uniform float u_vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float u_vignette_radius : hint_range(0.0, 1.0) = 0.55;

uniform float u_ca_impact = 0.0;

uniform float u_bloom_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float u_bloom_threshold : hint_range(0.0, 2.0) = 0.7;
uniform float u_bloom_blur_radius : hint_range(1.0, 16.0) = 5.0;
uniform vec3 u_bloom_tint : source_color = vec3(0.55, 0.85, 1.0);

uniform sampler2D iChannel0 : hint_screen_texture, filter_linear, repeat_disable;

// 13-tap single-pass bloom kernel: center + two cardinal rings + diagonal ring.
// Offsets are in pixels (multiplied by SCREEN_PIXEL_SIZE * u_bloom_blur_radius).
const vec2 BLOOM_OFFSETS[13] = vec2[13](
	vec2( 0.0,  0.0),
	vec2( 1.0,  0.0), vec2(-1.0,  0.0), vec2( 0.0,  1.0), vec2( 0.0, -1.0),
	vec2( 2.0,  0.0), vec2(-2.0,  0.0), vec2( 0.0,  2.0), vec2( 0.0, -2.0),
	vec2( 1.5,  1.5), vec2(-1.5,  1.5), vec2( 1.5, -1.5), vec2(-1.5, -1.5)
);
const float BLOOM_WEIGHTS[13] = float[13](
	0.25,
	0.10, 0.10, 0.10, 0.10,
	0.06, 0.06, 0.06, 0.06,
	0.05, 0.05, 0.05, 0.05
);
const float BLOOM_WEIGHT_SUM = 1.09;

vec3 bright_pass(vec3 c) {
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float k = clamp(l - u_bloom_threshold, 0.0, 1.0);
	return c * k;
}

void fragment() {
	vec2 uv = UV;
	vec4 col = texture(iChannel0, uv);

	if (u_ca_impact > 0.0) {
		float r = texture(iChannel0, uv + vec2(u_ca_impact, 0.0)).r;
		float g = texture(iChannel0, uv).g;
		float b = texture(iChannel0, uv + vec2(-u_ca_impact, 0.0)).b;
		col = vec4(r, g, b, col.a);
	}

	if (u_bloom_intensity > 0.0) {
		vec2 px = SCREEN_PIXEL_SIZE * u_bloom_blur_radius;
		vec3 bloom = vec3(0.0);
		for (int i = 0; i < 13; i++) {
			vec3 c = texture(iChannel0, uv + BLOOM_OFFSETS[i] * px).rgb;
			bloom += bright_pass(c) * BLOOM_WEIGHTS[i];
		}
		bloom /= BLOOM_WEIGHT_SUM;
		bloom *= u_bloom_tint * u_bloom_intensity;
		col.rgb += bloom;
	}

	float d = distance(uv, vec2(0.5, 0.5)) * 1.414;
	float v = 1.0 - smoothstep(u_vignette_radius, 1.0, d) * u_vignette_intensity;
	col.rgb *= v;

	COLOR = col;
}