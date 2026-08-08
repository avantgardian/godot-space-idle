shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/bodies/_planet_common.gdshaderinc"
#include "res://shaders/bodies/_noise.gdshaderinc"

uniform vec3  u_venus_cloud_hi : source_color = vec3(0.95, 0.85, 0.55);
uniform vec3  u_venus_cloud_lo : source_color = vec3(0.65, 0.45, 0.20);
uniform float u_cloud_swirl_amp : hint_range(0.0, 0.5) = 0.15;
uniform float u_cloud_swirl_freq : hint_range(1.0, 16.0) = 6.0;
uniform float u_cloud_contrast : hint_range(0.0, 1.0) = 0.6;
uniform float u_limb_brighten : hint_range(0.0, 1.0) = 0.0;
uniform float u_surface_lava_leak : hint_range(0.0, 1.0) = 0.0;
uniform vec3  u_lava_color : source_color = vec3(0.60, 0.15, 0.05);

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

		float warp = sin(lon * u_cloud_swirl_freq) * u_cloud_swirl_amp;
		float warped_lat = lat + warp;
		float bands = sin(warped_lat * 5.5 + sin(lon * 2.0) * 0.4);
		bands = bands * 0.5 + 0.5;
		float cloud_noise = fbm(vec2(lon, warped_lat) * 3.0 + seed_off);
		float combined = mix(bands, cloud_noise, 0.35);
		float c = u_cloud_contrast * 0.2;
		float cloud_t = smoothstep(0.5 - c, 0.5 + c, combined);
		vec3 base = mix(u_venus_cloud_lo, u_venus_cloud_hi, cloud_t);

		if (u_surface_lava_leak > 0.0) {
			float s1 = hash21(vec2(float(u_seed) * 0.137, 1.7));
			float s2 = hash21(vec2(float(u_seed) * 0.319, 2.3));
			float s3 = hash21(vec2(float(u_seed) * 0.523, 3.1));
			float s4 = hash21(vec2(float(u_seed) * 0.731, 4.4));
			float s5 = hash21(vec2(float(u_seed) * 0.913, 5.7));
			float s6 = hash21(vec2(float(u_seed) * 0.197, 6.9));
			float la1 = (s1 - 0.5) * 2.4;
			float lo1 = (s2 - 0.5) * 6.2832;
			float la2 = (s3 - 0.5) * 2.4;
			float lo2 = (s4 - 0.5) * 6.2832;
			float la3 = (s5 - 0.5) * 2.4;
			float lo3 = (s6 - 0.5) * 6.2832;
			vec3 lp1 = vec3(cos(la1) * sin(lo1), sin(la1), cos(la1) * cos(lo1));
			vec3 lp2 = vec3(cos(la2) * sin(lo2), sin(la2), cos(la2) * cos(lo2));
			vec3 lp3 = vec3(cos(la3) * sin(lo3), sin(la3), cos(la3) * cos(lo3));
			float lava_r = 0.12;
			float leak1 = smoothstep(lava_r, 0.0, acos(clamp(dot(n, lp1), -1.0, 1.0)));
			float leak2 = smoothstep(lava_r, 0.0, acos(clamp(dot(n, lp2), -1.0, 1.0)));
			float leak3 = smoothstep(lava_r, 0.0, acos(clamp(dot(n, lp3), -1.0, 1.0)));
			float leak = max(leak1, max(leak2, leak3)) * u_surface_lava_leak;
			base = mix(base, u_lava_color, leak * 0.7);
		}

		float limb_brighten_amount = 0.0;
		if (u_limb_brighten > 0.0) {
			limb_brighten_amount = u_limb_brighten * pow(1.0 - mu, 2.0);
		}

		vec3 col = base * lighting * limb + base * night_rim + base * limb_brighten_amount * lighting;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}
