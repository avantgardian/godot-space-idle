shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	float f = 1.0;
	for (int i = 0; i < 3; i++) {
		v += a * smooth_noise(p * f + time * 0.08 * float(i + 1));
		f *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.01) {
		vec2 uv = UV * 2.0 - 1.0;
		float dist = length(uv);
		float edge = 1.0 - smoothstep(0.0, 1.0, dist);
		float n = fbm(uv * 4.0) * edge;
		vec3 col = tex.rgb;
		col += vec3(n * 0.15, n * 0.08, n * 0.03);
		float spots = smooth_noise(uv * 10.0 + time * 0.05);
		spots = pow(spots, 3.0) * 0.12 * edge;
		col -= vec3(spots, spots * 0.8, spots * 0.5);
		col = clamp(col, 0.0, 1.0);
		COLOR = vec4(col, tex.a);
	} else { COLOR = tex; }
}
