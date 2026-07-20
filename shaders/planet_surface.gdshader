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

// Biome selector. 0 = none (use u_base_color path), 1 = rocky (#104),
// 2 = greenhouse (#105), 3 = terrestrial (#106).
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

// Greenhouse biome uniforms (#105).
uniform vec3  u_venus_cloud_hi = vec3(0.95, 0.85, 0.55);
uniform vec3  u_venus_cloud_lo = vec3(0.65, 0.45, 0.20);
uniform float u_cloud_swirl_amp   : hint_range(0.0, 0.5) = 0.15;
uniform float u_cloud_swirl_freq  : hint_range(1.0, 16.0) = 6.0;
uniform float u_cloud_contrast    : hint_range(0.0, 1.0) = 0.6;
uniform float u_limb_brighten     : hint_range(0.0, 1.0) = 0.0;   // additive limb brighten (greenhouse only)
uniform float u_surface_lava_leak  : hint_range(0.0, 1.0) = 0.0;   // 0 = no leak
uniform vec3  u_lava_color = vec3(0.60, 0.15, 0.05);

// Terrestrial biome uniforms (#106). Reuses u_polar_cap_lat and
// u_polar_softness from the rocky #104 uniforms above for the polar
// cutoff so a single set of polar params governs cap placement across
// biomes. u_terra_ice_cap is separate from u_polar_cap_color because
// Earth's sea ice is a different palette token (TERRA_ICE_CAP) than
// Mars's dusty frost (ROCKY_MARS_ICE).
uniform vec3  u_ocean_deep     = vec3(0.04, 0.18, 0.42);
uniform vec3  u_ocean_shallow  = vec3(0.10, 0.45, 0.65);
uniform vec3  u_land_tropical  = vec3(0.10, 0.45, 0.15);
uniform vec3  u_land_desert    = vec3(0.78, 0.65, 0.40);
uniform vec3  u_land_tundra    = vec3(0.55, 0.55, 0.40);
uniform vec3  u_terra_ice_cap  = vec3(0.92, 0.95, 1.00);
uniform vec3  u_terra_cloud_white = vec3(0.95, 0.95, 0.95);
uniform vec3  u_terra_specular    = vec3(0.95, 0.98, 1.00);
uniform float u_sea_level       : hint_range(0.0, 1.0) = 0.5;
uniform float u_ocean_shelf_depth : hint_range(0.01, 0.5) = 0.15;
uniform float u_cloud_coverage  : hint_range(0.0, 1.0) = 0.45;
uniform float u_cloud_spin_rate  = 0.15;            // rad/s — ~3x surface spin
uniform float u_cloud_scale     : hint_range(0.5, 12.0) = 3.0;
uniform float u_specular_power  : hint_range(1.0, 256.0) = 64.0;
uniform float u_city_lights     : hint_range(0.0, 1.0) = 0.0;   // 0 = no night-side city lights

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
		// Terrestrial (#106) cross-branch output channels. Defaults keep
		// them inert for non-terrestrial biomes; compositing below only
		// consumes them when u_biome_mode == 3.
		float spec_glint = 0.0;
		float cloud_alpha_out = 0.0;
		vec3  cloud_color_out = vec3(0.0);
		float land_mask = 0.0;          // 1 on land, 0 on ocean (for city lights)
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
		} else if (u_biome_mode == 2) {
			// Greenhouse (#105). The surface IS the cloud tops — no regolith
			// visible anywhere on the disk. Latitudinal belts+zones with
			// zonal wind shear (chevron "V" pattern) + fbm cloud detail.
			float warp = sin(lon * u_cloud_swirl_freq) * u_cloud_swirl_amp;
			float warped_lat = lat + warp;
			// Zonal banding: alternating bright zones and darker belts.
			// sin(lon*2) shears the bands longitudinally → chevron pattern.
			float bands = sin(warped_lat * 5.5 + sin(lon * 2.0) * 0.4);
			bands = bands * 0.5 + 0.5;
			// Fine cloud texture within bands.
			float cloud_noise = fbm(vec2(lon, warped_lat) * 3.0 + seed_off);
			float combined = mix(bands, cloud_noise, 0.35);
			float c = u_cloud_contrast * 0.2;
			float cloud_t = smoothstep(0.5 - c, 0.5 + c, combined);
			base = mix(u_venus_cloud_lo, u_venus_cloud_hi, cloud_t);

			// Optional hot-glow leak (off by default — Venus's surface is
			// never actually visible through the cloud deck). 3 deterministic
			// spot positions derived from u_seed via hash21. Gated by
			// u_surface_lava_leak > 0 so the entire branch is a no-op (and
			// skips the acos work) when disabled.
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
		} else if (u_biome_mode == 3) {
			// Terrestrial (#106) — Earth-like habitable worlds.
			// Continent fbm at low freq so land masses read as large shapes,
			// not speckle. (Sampled directly in lat/lon, NOT via
			// u_noise_scale which is tuned for rocky/greenhouse grain.)
			// fbm's native range clusters around its mean (~0.47) with a
			// narrow spread, so a *max* remap (÷0.9375) leaves most pixels
			// below 0.5. Instead, center-remap the mid-band [0.35, 0.65] to
			// [0,1] — the Mars #104 smoothstep(0.2, 0.8, grain) technique —
			// so u_sea_level=0.5 gives an even land/ocean split.
			vec2 surfc = vec2(lon, lat) * 1.5 + seed_off;
			float cont_raw = fbm(surfc);
			float cont = smoothstep(0.32, 0.62, cont_raw);

			// Polar ice caps (land + sea ice). Computed up here so we can
			// re-use the mask for both land and ocean pixels. cap_t runs
			// 0 at u_polar_cap_lat to 1 at u_polar_cap_lat + u_polar_softness;
			// softness is in RADIANS (default 0.12 ≈ 7 degrees of feather).
			float ice_amt = 0.0;
			if (u_polar_cap_lat > 0.0) {
				float abs_lat = abs(lat);
				float cap_t = (abs_lat - u_polar_cap_lat) / u_polar_softness;
				ice_amt = smoothstep(0.0, 1.0, cap_t);
				// Fray the cap edge with fbm so it's not a perfect circle,
				// but remap so the cap still reads as solid ice at the pole.
				float fray = fbm(vec2(lon * 2.0, lat * 4.0) + seed_off) / 0.9375;
				ice_amt *= mix(0.7, 1.0, smoothstep(0.3, 0.7, fray));
			}

			bool is_land = cont > u_sea_level;
			if (is_land) {
				land_mask = 1.0;
				float abs_lat = abs(lat);
				// Latitude-keyed biome ramp: tropical near equator, desert
				// at mid latitudes, tundra near the poles.
				float trop_mask    = 1.0 - smoothstep(0.35, 0.6, abs_lat);
				float desert_mask  = smoothstep(0.35, 0.6, abs_lat) * (1.0 - smoothstep(0.85, 1.10, abs_lat));
				float tundra_mask  = smoothstep(0.85, 1.10, abs_lat);
				vec3 land_col = u_land_tropical * trop_mask
				              + u_land_desert * desert_mask
				              + u_land_tundra  * tundra_mask;
				// Continent detail noise so landmasses aren't a flat tint —
				// sampled at higher freq and a decorrelated offset so it
				// doesn't track the continent mask. Center-remap by
				// smoothstep so the detail ±u_surface_grain_amp actually
				// swings rather than pinching around the fbm mean.
				float detail = smoothstep(0.32, 0.62, fbm(surfc * 5.0 + seed_off * 2.7));
				land_col *= (1.0 + (detail * 2.0 - 1.0) * u_surface_grain_amp);
				base = land_col;
			} else {
				// Ocean — depth-keyed ramp from shallow (continental shelf)
				// to deep (below thermocline).
				float depth = u_sea_level - cont;
				float depth_t = smoothstep(0.0, u_ocean_shelf_depth, depth);
				base = mix(u_ocean_shallow, u_ocean_deep, depth_t);
				// Sparkle noise mask reused by the glint below.
				float spark = fbm(vec2(lon * 8.0, lat * 8.0) + seed_off * 1.7);
				// Specular sun glint (Blinn-Phong, camera = +Z). Tight
				// highlight only on the day-side ocean.
				if (diff > 0.0) {
					vec3 V = vec3(0.0, 0.0, 1.0);
					vec3 H = normalize(V + L);
					float spec = pow(max(dot(n, H), 0.0), u_specular_power);
					spec *= (0.7 + 0.3 * spark);
					spec_glint = spec;
				}
			}

			// Apply polar ice to BOTH land and ocean (sea ice extends
			// the polar cap from land out over the ocean).
			if (ice_amt > 0.0) {
				base = mix(base, u_terra_ice_cap, ice_amt * 0.92);
			}

			// Cloud layer — independent fbm at its own offset/scale and
			// its own spin rate (u_cloud_spin_rate is ~3x faster than the
			// surface u_spin_rate). Clouds cast no shadow (#114 scope).
			// Re-derive the spinning longitude in the tilted frame so the
			// cloud drift is independent of the surface spin.
			float cloud_lon = atan(n.x, n.z) + u_time * u_cloud_spin_rate;
			vec2 cloud_uv = vec2(cloud_lon, lat) * u_cloud_scale + seed_off * 2.31;
			// Center-remap fbm so cloud_n actually spans [0,1] across the
			// disk (same smoothstep technique as the continent mask).
			float cloud_n = smoothstep(0.32, 0.62, fbm(cloud_uv));
			// Threshold by u_cloud_coverage for alpha. Wider transition
			// band (0.25) so cloud edges feather rather than cut sharp —
			// real clouds have wispy boundaries, not cookie-cutter edges.
			float cov_lo = u_cloud_coverage;
			float cov_hi = min(u_cloud_coverage + 0.25, 1.0);
			cloud_alpha_out = smoothstep(cov_lo, cov_hi, cloud_n);
			// Slightly off-white and alpha-capped so clouds read as soft
			// wisps instead of opaque ice floes. Lit by the same Lambert
			// term below, so the day side is still bright.
			cloud_color_out = u_terra_cloud_white * 0.85;
		} else {
			// Default (#102) path — base color tinted +/- u_noise_amp by fbm.
			float noise_val = fbm(vec2(lon, lat) * u_noise_scale + seed_off);
			base = mix(u_base_color * (1.0 - u_noise_amp),
			           u_base_color * (1.0 + u_noise_amp),
			           noise_val);
		}

		// Additive limb brighten for greenhouse biomes (Venus photographs
		// brighter at the limb because we're looking through a longer column
		// of scattering cloud). Scaled by lighting so the brighten picks up
		// the ambient floor on the night side.
		float limb_brighten_amount = 0.0;
		if (u_biome_mode == 2 && u_limb_brighten > 0.0) {
			limb_brighten_amount = u_limb_brighten * pow(1.0 - mu, 2.0);
		}

		// Night-side ambient-ish glow uses base color so the silhouette still
		// reads in the planet's own hue (Mars red, Mercury grey).
		vec3 col = base * lighting * limb + base * night_rim + base * limb_brighten_amount * lighting;

		// Terrestrial (#106) top-layer compositing: clouds blended over
		// the lit surface, ocean specular glint added on top, optional
		// night-side city lights. Everything here is a no-op for other
		// biomes because the cross-branch outputs default to 0.
		if (u_biome_mode == 3) {
			// Clouds lit by the same Lambert term so the day side is
			// bright and the night side fades to the ambient floor.
			// Alpha capped at 0.7 so surface features still read through
			// the cloud deck (real clouds are translucent from orbit).
			vec3 cloud_col = cloud_color_out * (lighting * limb + u_ambient * 0.5);
			col = mix(col, cloud_col, cloud_alpha_out * 0.7);
			// Ocean specular highlight. Multiply by lighting so the glint
			// only appears on the day side and fades across terminator.
			col += u_terra_specular * spec_glint * lighting;
			// Optional night-side city lights — no-op when u_city_lights
			// is 0.0 (acceptance criterion). Restricted to land so cities
			// don't glow on the ocean floor.
			if (u_city_lights > 0.0 && land_mask > 0.5) {
				float dark = 1.0 - diff;
				float dark_mask = smoothstep(0.5, 1.0, dark);
				// Cluster city lights using a high-frequency fbm so they
				// appear in deterministic patches, not uniformly.
				float city_n = fbm(vec2(lon * 12.0, lat * 12.0) + seed_off * 3.7);
				float city_field = smoothstep(0.65, 0.75, city_n);
				col += vec3(1.0, 0.85, 0.55) * city_field * u_city_lights * dark_mask;
			}
		}

		COLOR = vec4(col, tex.a * edge_aa);
	}
}