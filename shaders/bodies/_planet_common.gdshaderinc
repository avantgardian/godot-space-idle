void sphere_projection(vec2 uv_ndc, float axial_tilt, float time_val, float spin_rate, int seed, out float mu, out float lat, out float lon, out vec3 n, out vec2 seed_off, out float edge_aa) {
	float r2 = min(dot(uv_ndc, uv_ndc), 1.0);
	mu = sqrt(1.0 - r2);
	edge_aa = 1.0 - smoothstep(0.97, 1.0, dot(uv_ndc, uv_ndc));
	vec3 n_view = vec3(uv_ndc, mu);
	float ct = cos(axial_tilt);
	float st = sin(axial_tilt);
	n = vec3(n_view.x, n_view.y * ct - n_view.z * st, n_view.y * st + n_view.z * ct);
	lat = asin(clamp(n.y, -1.0, 1.0));
	lon = atan(n.x, n.z) + time_val * spin_rate;
	seed_off = vec2(float(seed) * 1.7, float(seed) * 0.93);
}

void compute_lighting(vec3 n, vec3 light_dir, float ambient, float limb_strength, float night_rim_strength, float mu, out float diff, out float lighting, out float limb, out float night_rim) {
	vec3 L = normalize(light_dir);
	diff = max(dot(n, L), 0.0);
	lighting = mix(ambient, 1.0, diff);
	limb = (1.0 + 1.5 * mu) / 2.5;
	limb = mix(1.0, limb, limb_strength);
	float dark_side = 1.0 - diff;
	float rim = pow(1.0 - mu, 3.0);
	night_rim = rim * dark_side * night_rim_strength;
}

uniform float u_time = 0.0;
uniform vec3  u_light_dir = vec3(-1.0, 0.0, 0.0);
uniform float u_ambient : hint_range(0.0, 0.5) = 0.06;
uniform float u_night_rim : hint_range(0.0, 1.0) = 0.4;
uniform float u_limb : hint_range(0.0, 1.0) = 0.35;
uniform float u_axial_tilt = 0.0;
uniform float u_spin_rate = 0.05;
uniform int   u_seed = 1;
