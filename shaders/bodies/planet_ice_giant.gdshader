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

uniform vec3  u_ice_base_color : source_color = vec3(0.30, 0.65, 0.85);
uniform float u_ice_band_contrast : hint_range(0.0, 0.5) = 0.03;
uniform vec3  u_ice_haze_color : source_color = vec3(0.85, 0.92, 1.00);
uniform float u_ice_haze_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3  u_ice_storm_dark : source_color = vec3(0.04, 0.10, 0.30);
uniform int   u_ice_variant : hint_range(0, 1) = 0;
uniform int   u_band_count : hint_range(1, 20) = 12;
uniform float u_storm_stretch = 3.0;
uniform int   u_storm_count : hint_range(0, 16) = 0;
uniform vec2  u_storm_pos[16];
uniform float u_storm_size[16];
uniform float u_storm_strength[16];
uniform int   u_storm_kind[16];
uniform vec3  u_storm_white : source_color = vec3(0.95, 0.95, 0.95);

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

		vec3 base = u_ice_base_color;

		float si_bands = sin(lat * float(u_band_count) * 0.8) * 0.5 + 0.5;
		si_bands += fbm(vec2(lon, lat) * 3.0 + seed_off * 1.3) * 0.04 - 0.02;
		vec3 ice_lo = u_ice_base_color * (1.0 - u_ice_band_contrast);
		vec3 ice_hi = u_ice_base_color * (1.0 + u_ice_band_contrast);
		base = mix(ice_lo, ice_hi, si_bands);

		if (u_ice_variant == 1 && u_ice_haze_strength > 0.0) {
			vec2 haze_uv = vec2(lon, lat) * 4.0 + seed_off * 3.1;
			float haze_n = fbm(vec2(haze_uv.x * 0.25, haze_uv.y * 2.0));
			haze_n = smoothstep(0.35, 0.65, haze_n);
			base = mix(base, u_ice_haze_color, haze_n * u_ice_haze_strength);
		}

		for (int i = 0; i < 16; i++) {
			if (i >= u_storm_count) break;
			float slat = u_storm_pos[i].x;
			float slon = u_storm_pos[i].y;
			float dlat = lat - slat;
			float dlon = lon - slon;
			dlon = mod(dlon + 3.14159, 6.28318) - 3.14159;

			float ellip = sqrt(dlon * dlon + dlat * dlat * u_storm_stretch * u_storm_stretch);
			float sr = u_storm_size[i];
			float t_norm = ellip / sr;

			float falloff = 1.0 - smoothstep(0.25, 1.0, t_norm);
			if (falloff > 0.0) {
				vec3 storm_col;
				if (u_storm_kind[i] == 2) {
					storm_col = u_ice_storm_dark;
				} else if (u_storm_kind[i] == 1) {
					storm_col = u_storm_white;
				} else {
					storm_col = u_ice_storm_dark;
				}
				float blend = falloff * u_storm_strength[i];
				base = mix(base, storm_col, blend * 0.7);
			}
		}

		vec3 col = base * lighting * limb + base * night_rim;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}
