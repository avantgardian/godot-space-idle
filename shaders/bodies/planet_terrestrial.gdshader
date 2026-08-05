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

uniform float u_surface_grain_amp : hint_range(0.0, 0.5) = 0.15;
uniform float u_polar_cap_lat : hint_range(0.0, 1.5708) = 0.0;
uniform float u_polar_softness : hint_range(0.01, 0.5) = 0.1;
uniform vec3  u_terra_ice_cap = vec3(0.92, 0.95, 1.00);
uniform vec3  u_ocean_deep = vec3(0.04, 0.18, 0.42);
uniform vec3  u_ocean_shallow = vec3(0.10, 0.45, 0.65);
uniform vec3  u_land_tropical = vec3(0.10, 0.45, 0.15);
uniform vec3  u_land_desert = vec3(0.78, 0.65, 0.40);
uniform vec3  u_land_tundra = vec3(0.55, 0.55, 0.40);
uniform vec3  u_terra_cloud_white = vec3(0.95, 0.95, 0.95);
uniform vec3  u_terra_specular = vec3(0.95, 0.98, 1.00);
uniform float u_sea_level : hint_range(0.0, 1.0) = 0.5;
uniform float u_ocean_shelf_depth : hint_range(0.01, 0.5) = 0.15;
uniform float u_cloud_coverage : hint_range(0.0, 1.0) = 0.45;
uniform float u_cloud_spin_rate = 0.15;
uniform float u_cloud_scale : hint_range(0.5, 12.0) = 3.0;
uniform float u_specular_power : hint_range(1.0, 256.0) = 64.0;
uniform float u_city_lights : hint_range(0.0, 1.0) = 0.0;

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

		vec2 surfc = vec2(lon, lat) * 1.5 + seed_off;
		float cont_raw = fbm(surfc);
		float cont = smoothstep(0.32, 0.62, cont_raw);

		float ice_amt = 0.0;
		if (u_polar_cap_lat > 0.0) {
			float abs_lat = abs(lat);
			float cap_t = (abs_lat - u_polar_cap_lat) / u_polar_softness;
			ice_amt = smoothstep(0.0, 1.0, cap_t);
			float fray = fbm(vec2(lon * 2.0, lat * 4.0) + seed_off) / 0.9375;
			ice_amt *= mix(0.7, 1.0, smoothstep(0.3, 0.7, fray));
		}

		vec3 base;
		float land_mask = 0.0;
		float spec_glint = 0.0;
		bool is_land = cont > u_sea_level;

		if (is_land) {
			land_mask = 1.0;
			float abs_lat = abs(lat);
			float trop_mask = 1.0 - smoothstep(0.35, 0.6, abs_lat);
			float desert_mask = smoothstep(0.35, 0.6, abs_lat) * (1.0 - smoothstep(0.85, 1.10, abs_lat));
			float tundra_mask = smoothstep(0.85, 1.10, abs_lat);
			vec3 land_col = u_land_tropical * trop_mask
			              + u_land_desert * desert_mask
			              + u_land_tundra  * tundra_mask;
			float detail = smoothstep(0.32, 0.62, fbm(surfc * 5.0 + seed_off * 2.7));
			land_col *= (1.0 + (detail * 2.0 - 1.0) * u_surface_grain_amp);
			base = land_col;
		} else {
			float depth = u_sea_level - cont;
			float depth_t = smoothstep(0.0, u_ocean_shelf_depth, depth);
			base = mix(u_ocean_shallow, u_ocean_deep, depth_t);
			float spark = fbm(vec2(lon * 8.0, lat * 8.0) + seed_off * 1.7);
			if (diff > 0.0) {
				vec3 V = vec3(0.0, 0.0, 1.0);
				vec3 H = normalize(V + normalize(u_light_dir));
				float spec = pow(max(dot(n, H), 0.0), u_specular_power);
				spec *= (0.7 + 0.3 * spark);
				spec_glint = spec;
			}
		}

		if (ice_amt > 0.0) {
			base = mix(base, u_terra_ice_cap, ice_amt * 0.92);
		}

		float cloud_alpha_out = 0.0;
		vec3  cloud_color_out = vec3(0.0);
		float cloud_lon = atan(n.x, n.z) + u_time * u_cloud_spin_rate;
		vec2 cloud_uv = vec2(cloud_lon, lat) * u_cloud_scale + seed_off * 2.31;
		float cloud_n = smoothstep(0.32, 0.62, fbm(cloud_uv));
		float cov_lo = u_cloud_coverage;
		float cov_hi = min(u_cloud_coverage + 0.25, 1.0);
		cloud_alpha_out = smoothstep(cov_lo, cov_hi, cloud_n);
		cloud_color_out = u_terra_cloud_white * 0.85;

		vec3 col = base * lighting * limb + base * night_rim;

		vec3 cloud_col = cloud_color_out * (lighting * limb + u_ambient * 0.5);
		col = mix(col, cloud_col, cloud_alpha_out * 0.7);
		col += u_terra_specular * spec_glint * lighting;

		if (u_city_lights > 0.0 && land_mask > 0.5) {
			float dark = 1.0 - diff;
			float dark_mask = smoothstep(0.5, 1.0, dark);
			float city_n = fbm(vec2(lon * 12.0, lat * 12.0) + seed_off * 3.7);
			float city_field = smoothstep(0.65, 0.75, city_n);
			col += vec3(1.0, 0.85, 0.55) * city_field * u_city_lights * dark_mask;
		}

		COLOR = vec4(col, tex.a * edge_aa);
	}
}
