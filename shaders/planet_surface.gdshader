shader_type canvas_item;
render_mode unshaded;

// Driven each frame by OrbitalBody._process.
uniform float u_time = 0.0;
uniform vec3  u_light_dir = vec3(1.0, 0.0, 0.0);   // world-space, normalized, points planet -> sun

// Set once per-instance in OrbitalBody._apply_planet_shader from @export fields.
uniform float u_ambient   : hint_range(0.0, 0.5) = 0.06;
uniform float u_night_rim : hint_range(0.0, 1.0) = 0.4;
uniform float u_limb      : hint_range(0.0, 1.0) = 0.35;
uniform float u_axial_tilt = 0.0;                   // radians
uniform float u_spin_rate = 0.05;                   // rad/s of surface texture "spin"
uniform int   u_seed = 1;

// Biome identity. Per-type issues (#104-#109) override these with biome-specific
// noise + extra uniforms layered on top.
uniform vec3  u_base_color  = vec3(0.5);
uniform float u_noise_scale = 4.0;
uniform float u_noise_amp   : hint_range(0.0, 1.0) = 0.15;

// Biome selector. 0 = none (use u_base_color path), 1 = rocky (#104).
// Subsequent biomes will add 2..N.
uniform int u_biome_mode = 0;

// Rocky biome uniforms (#104).
uniform vec3  u_rocky_hi = vec3(0.62, 0.58, 0.55);   // bright regolith
uniform vec3  u_rocky_lo = vec3(0.30, 0.27, 0.25);   // dark regolith / crater shadow
uniform float u_surface_grain_amp : hint_range(0.0, 0.5) = 0.15;
uniform int   u_crater_count : hint_range(0, 16) = 0;
uniform vec2  u_crater_pos[16];    // (lat, lon) radians
uniform float u_crater_size[16];   // angular radius radians
uniform float u_crater_strength[16];
uniform float u_polar_cap_lat  : hint_range(0.0, 1.5708) = 0.0;  // 0 = no caps
uniform float u_polar_softness : hint_range(0.01, 0.5) = 0.1;
uniform vec3  u_polar_cap_color = vec3(0.90, 0.85, 0.80);

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

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv = UV * 2.0 - 1.0;
		float r2 = min(dot(uv, uv), 1.0);
		float mu = sqrt(1.0 - r2);
		float edge_aa = 1.0 - smoothstep(0.97, 1.0, dot(UV * 2.0 - 1.0, UV * 2.0 - 1.0));

		// Surface normal in view space (z toward camera).
		vec3 n_view = vec3(uv, mu);
		// Axial tilt around the X axis so the planet's north pole tips
		// toward/away from the camera (Uranus's ~98 deg is the extreme case).
		float ct = cos(u_axial_tilt);
		float st = sin(u_axial_tilt);
		vec3 n = vec3(n_view.x, n_view.y * ct - n_view.z * st, n_view.y * st + n_view.z * ct);

		// Spherical lat/lon in the tilted frame for surface noise sampling.
		// Surface spin advances longitude so features drift across the disk.
		float lat = asin(clamp(n.y, -1.0, 1.0));
		float lon = atan(n.x, n.z) + u_time * u_spin_rate;
		vec2 seed_off = vec2(float(u_seed) * 1.7, float(u_seed) * 0.93);

		// Lambert diffuse; ambient floor keeps the night side readable.
		vec3 L = normalize(u_light_dir);
		float diff = max(dot(n, L), 0.0);
		float lighting = mix(u_ambient, 1.0, diff);

		// Limb darkening (matches sun_surface.gdshader form).
		float limb = (1.0 + 1.5 * mu) / 2.5;
		limb = mix(1.0, limb, u_limb);

		// Dark-side limb brighten: a thin rim of scattered light around the
		// planet's night silhouette so the full outline reads against the BG.
		float dark_side = 1.0 - diff;
		float rim = pow(1.0 - mu, 3.0);
		float night_rim = rim * dark_side * u_night_rim;

		// Surface color — biome-specific.
		vec3 base;
		if (u_biome_mode == 1) {
			// Rocky (#104). High-frequency grain tinted between rocky_hi/lo.
			float grain = fbm(vec2(lon, lat) * u_noise_scale + seed_off);
			float g2 = grain * 2.0 - 1.0;
			base = mix(u_rocky_lo, u_rocky_hi, smoothstep(0.2, 0.8, grain));
			// Extra fine-grain speckle on top, scaled by light so the night side stays dark.
			float speckle = fbm(vec2(lon, lat) * u_noise_scale * 3.5 + seed_off * 1.7);
			base *= (1.0 + (speckle * 2.0 - 1.0) * u_surface_grain_amp);

			// Craters: stone analog of sunspots. For each crater, compute angular
			// distance from the surface point; inside the radius, darken the pit
			// and brighten the sun-ward rim using dot(pit_normal, L).
			float crater_darken = 0.0;
			float crater_rim = 0.0;
			for (int i = 0; i < 16; i++) {
				if (i >= u_crater_count) break;
				float clat = u_crater_pos[i].x;
				float clon = u_crater_pos[i].y;
				vec3 cp = vec3(cos(clat) * sin(clon), sin(clat), cos(clat) * cos(clon));
				float d = dot(n, cp);
				float ang = acos(clamp(d, -1.0, 1.0));
				float sr = u_crater_size[i];
				if (ang < sr) {
					float t_norm = ang / sr;  // 0 center, 1 rim
					// Pit darkens toward the center; sign keeps night-side craters dim.
					float pit = smoothstep(1.0, 0.0, t_norm) * u_crater_strength[i];
					// Rim brighten: only on the sun-ward side, peaks at the rim,
					// fades toward the pit center and outside the crater.
					float rim_band = smoothstep(0.0, 0.3, t_norm) * (1.0 - smoothstep(0.7, 1.0, t_norm));
					float sun_side = max(dot(cp, L), 0.0);
					float brighten = rim_band * sun_side * u_crater_strength[i] * 0.6;
					// Soft limb fade so craters rotate in/out without popping.
					float limb_fade = smoothstep(0.0, 0.30, d);
					crater_darken = max(crater_darken, pit * limb_fade);
					crater_rim = max(crater_rim, brighten * limb_fade);
				}
			}
			base = base * (1.0 - crater_darken) + crater_rim * u_rocky_hi;

			// Polar caps (Mars). Latitude-keyed frost above u_polar_cap_lat,
			// feathered by u_polar_softness. Frayed by fbm so the cap edge isn't
			// a perfect circle.
			if (u_polar_cap_lat > 0.0) {
				float abs_lat = abs(lat);
				float cap_t = (abs_lat - u_polar_cap_lat) / u_polar_softness;
				float cap_mask = smoothstep(0.0, 1.0, cap_t);
				float fray = fbm(vec2(lon * 2.0, lat * 4.0) + seed_off);
				cap_mask *= smoothstep(0.3, 0.7, fray);
				base = mix(base, u_polar_cap_color, cap_mask * 0.85);
			}
		} else {
			// Default (#102) path — base color tinted +/- u_noise_amp by fbm.
			float noise_val = fbm(vec2(lon, lat) * u_noise_scale + seed_off);
			base = mix(u_base_color * (1.0 - u_noise_amp),
			           u_base_color * (1.0 + u_noise_amp),
			           noise_val);
		}

		// Night-side ambient-ish glow uses base color so the silhouette still
		// reads in the planet's own hue (Mars red, Mercury grey).
		vec3 col = base * lighting * limb + base * night_rim;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}