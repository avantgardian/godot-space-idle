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

uniform float u_time = 0.0;
uniform vec3 u_light_dir = vec3(1.0, 0.0, 0.0);
uniform float u_ambient : hint_range(0.0, 0.5) = 0.08;
uniform int u_seed = 1;
uniform float u_spin_rate = 1.5;
uniform vec3 u_base_color = vec3(0.5, 0.42, 0.35);
uniform vec3 u_regolith_hi = vec3(0.55, 0.48, 0.42);
uniform vec3 u_regolith_lo = vec3(0.25, 0.20, 0.16);
uniform float u_relief_depth : hint_range(0.0, 0.4) = 0.15;
uniform float u_irregularity : hint_range(0.0, 0.5) = 0.20;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv_ndc = UV * 2.0 - 1.0;

		float spin_angle = u_time * u_spin_rate;
		float cs = cos(spin_angle);
		float sn = sin(spin_angle);
		vec2 uv_spun = vec2(uv_ndc.x * cs - uv_ndc.y * sn, uv_ndc.x * sn + uv_ndc.y * cs);

		float r2_spun = dot(uv_spun, uv_spun);
		float r_spun = sqrt(r2_spun);

		float r2_light = dot(uv_ndc, uv_ndc);
		float r_light = sqrt(r2_light);

		float angle = atan(uv_spun.y, uv_spun.x);
		float ap = angle * 0.159154943 + float(u_seed) * 0.0173;
		float silhouette = fbm(vec2(ap * 8.0, float(u_seed) * 0.031));
		silhouette += fbm(vec2(ap * 22.0 + 1.3, float(u_seed) * 0.059)) * 0.35;
		silhouette += fbm(vec2(ap * 55.0 + 2.7, float(u_seed) * 0.093)) * 0.18;
		float silhouette_val = (silhouette - 0.4) * 2.5;
		float mask_radius = 1.0 - u_irregularity * silhouette_val;

		if (r_spun > mask_radius) {
			COLOR = vec4(0.0);
		} else {
			float edge_aa = 1.0 - smoothstep(mask_radius - 0.05, mask_radius, r_spun);

			float disk_r = min(r_light, 0.999);
			float mu = sqrt(1.0 - disk_r * disk_r);

			vec3 n_light = vec3(uv_ndc.x, uv_ndc.y, mu);
			n_light = normalize(n_light);

			vec3 n_spun = vec3(uv_spun.x, uv_spun.y, mu);
			n_spun = normalize(n_spun);
			float lat_spun = asin(clamp(n_spun.y, -1.0, 1.0));
			float lon_spun = atan(n_spun.x, n_spun.z);

			float relief = fbm(vec2(lon_spun, lat_spun) * 3.0 + vec2(float(u_seed) * 1.7, float(u_seed) * 0.93));
			float bump = (relief * 2.0 - 1.0) * u_relief_depth;
			vec3 n_relief = normalize(vec3(n_light.x + bump * 0.5, n_light.y + bump * 0.5, n_light.z));

			vec3 L = normalize(u_light_dir);
			float diff = max(dot(n_relief, L), 0.0);
			float lighting = mix(u_ambient, 1.0, diff);

			float limb = (1.0 + 1.5 * mu) / 2.5;

			float tint = fbm(vec2(lon_spun, lat_spun) * 5.0 + vec2(float(u_seed) * 3.7, float(u_seed) * 2.3));
			vec3 base = mix(u_regolith_lo, u_regolith_hi, tint);
			base *= u_base_color;

			vec3 col = base * lighting * limb;
			COLOR = vec4(col, tex.a * edge_aa);
		}
	}
}
