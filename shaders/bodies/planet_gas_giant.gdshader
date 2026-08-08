shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/bodies/_planet_common.gdshaderinc"
#include "res://shaders/bodies/_noise.gdshaderinc"

uniform vec3  u_gas_band_hi : source_color = vec3(0.88, 0.78, 0.55);
uniform vec3  u_gas_band_lo : source_color = vec3(0.50, 0.32, 0.18);
uniform int   u_band_count : hint_range(1, 20) = 12;
uniform float u_band_sharp : hint_range(0.01, 0.5) = 0.15;
uniform float u_shear_amp = 0.10;
uniform float u_band_warp : hint_range(0.0, 0.2) = 0.05;
uniform float u_storm_stretch = 3.0;
uniform vec3  u_storm_rust : source_color = vec3(0.85, 0.30, 0.20);
uniform vec3  u_storm_white : source_color = vec3(0.95, 0.95, 0.95);
uniform int   u_storm_count : hint_range(0, 16) = 0;
uniform vec2  u_storm_pos[16];
uniform float u_storm_size[16];
uniform float u_storm_strength[16];
uniform int   u_storm_kind[16];

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

		float sheared_lon = lon + sin(lat * 6.0) * u_shear_amp;

		float band_fbm = fbm(vec2(sheared_lon * 0.3, lat) * 1.5 + seed_off);
		float band_sin = sin(lat * float(u_band_count) * 0.8) * 0.5 + 0.5;
		float bands = band_fbm * 0.5 + band_sin * 0.5;

		vec3 deep  = u_gas_band_lo;
		vec3 mid   = mix(u_gas_band_hi, u_gas_band_lo, 0.45);
		vec3 pale  = u_gas_band_hi;
		vec3 cream = mix(pale, vec3(0.94, 0.92, 0.88), 0.7);

		float t = bands;
		vec3 base = deep;
		base = mix(base, mid,   smoothstep(0.20, 0.32, t));
		base = mix(base, pale,  smoothstep(0.32, 0.55, t));
		base = mix(base, cream, smoothstep(0.55, 0.70, t));
		base = mix(base, pale,  smoothstep(0.70, 0.88, t));

		float grain = fbm(vec2(sheared_lon, lat) * 4.0 + seed_off * 1.7);
		base *= (0.93 + grain * 0.14);

		for (int i = 0; i < 16; i++) {
			if (i >= u_storm_count) break;
			float slat = u_storm_pos[i].x;
			float slon = u_storm_pos[i].y;
			float dlat = lat - slat;
			float dlon = lon - slon;
			dlon = mod(dlon + PI, TAU) - PI;

			float ellip = sqrt(dlon * dlon + dlat * dlat * u_storm_stretch * u_storm_stretch);
			float sr = u_storm_size[i];
			float t_norm = ellip / sr;

			float falloff = 1.0 - smoothstep(0.25, 1.0, t_norm);
			if (falloff > 0.0) {
				vec3 storm_col = u_storm_kind[i] == 1 ? u_storm_white : u_storm_rust;
				float blend = falloff * u_storm_strength[i];
				base = mix(base, storm_col, blend * 0.7);
			}
		}

		vec3 col = base * lighting * limb + base * night_rim;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}
