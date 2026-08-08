shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/bodies/_planet_common.gdshaderinc"
#include "res://shaders/bodies/_noise.gdshaderinc"

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
		compute_lighting(uv, u_light_dir, u_ambient, u_limb, u_night_rim, mu, diff, lighting, limb, night_rim);

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
