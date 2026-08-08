shader_type canvas_item;
render_mode unshaded;

float hash21(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float smooth_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
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
	for (int i = 0; i < 4; i++) {
		v += a * smooth_noise(p * f);
		f *= 2.0;
		a *= 0.5;
	}
	return v;
}

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

uniform float u_noise_scale = 4.0;
uniform vec3  u_rocky_hi : source_color = vec3(0.62, 0.58, 0.55);
uniform vec3  u_rocky_lo : source_color = vec3(0.30, 0.27, 0.25);
uniform float u_surface_grain_amp : hint_range(0.0, 0.5) = 0.15;
uniform int   u_crater_count : hint_range(0, 16) = 0;
uniform vec2  u_crater_pos[16];
uniform float u_crater_size[16];
uniform float u_crater_strength[16];
uniform float u_polar_cap_lat : hint_range(0.0, 1.5708) = 0.0;
uniform float u_polar_softness : hint_range(0.01, 0.5) = 0.1;
uniform vec3  u_polar_cap_color : source_color = vec3(0.90, 0.85, 0.80);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv = UV * 2.0 - 1.0;
		float mu, lat, lon, edge_aa;
		vec3 n;
		vec2 seed_off;
		sphere_projection(uv, u_axial_tilt, u_time, u_spin_rate, u_seed, mu, lat, lon, n, seed_off, edge_aa);

		float diff, lighting, limb, night_rim;
		compute_lighting(n, u_light_dir, u_ambient, u_limb, u_night_rim, mu, diff, lighting, limb, night_rim);

		float grain = fbm(vec2(lon, lat) * u_noise_scale + seed_off);
		float g2 = grain * 2.0 - 1.0;
		vec3 base = mix(u_rocky_lo, u_rocky_hi, smoothstep(0.2, 0.8, grain));

		float speckle = fbm(vec2(lon, lat) * u_noise_scale * 3.5 + seed_off * 1.7);
		base *= (1.0 + (speckle * 2.0 - 1.0) * u_surface_grain_amp);

		float crater_darken = 0.0;
		float crater_rim = 0.0;
		vec3 L = normalize(u_light_dir);
		for (int i = 0; i < 16; i++) {
			if (i >= u_crater_count) break;
			float clat = u_crater_pos[i].x;
			float clon = u_crater_pos[i].y;
			vec3 cp = vec3(cos(clat) * sin(clon), sin(clat), cos(clat) * cos(clon));
			float d = dot(n, cp);
			float ang = acos(clamp(d, -1.0, 1.0));
			float sr = u_crater_size[i];
			if (ang < sr) {
				float t_norm = ang / sr;
				float pit = smoothstep(1.0, 0.0, t_norm) * u_crater_strength[i];
				float rim_band = smoothstep(0.0, 0.3, t_norm) * (1.0 - smoothstep(0.7, 1.0, t_norm));
				float sun_side = max(dot(cp, L), 0.0);
				float brighten = rim_band * sun_side * u_crater_strength[i] * 0.6;
				float limb_fade = smoothstep(0.0, 0.30, d);
				crater_darken = max(crater_darken, pit * limb_fade);
				crater_rim = max(crater_rim, brighten * limb_fade);
			}
		}
		base = base * (1.0 - crater_darken) + crater_rim * u_rocky_hi;

		if (u_polar_cap_lat > 0.0) {
			float abs_lat = abs(lat);
			float cap_t = (abs_lat - u_polar_cap_lat) / u_polar_softness;
			float cap_mask = smoothstep(0.0, 1.0, cap_t);
			float fray = fbm(vec2(lon * 2.0, lat * 4.0) + seed_off);
			cap_mask *= smoothstep(0.3, 0.7, fray);
			base = mix(base, u_polar_cap_color, cap_mask * 0.85);
		}

		vec3 col = base * lighting * limb + base * night_rim;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}
