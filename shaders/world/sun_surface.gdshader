shader_type canvas_item;

uniform float time : hint_range(0.0, 600.0) = 0.0;

uniform float u_limb_strength   : hint_range(0.0, 1.0) = 0.65;
uniform float u_granulation_scale : hint_range(0.2, 8.0) = 1.0;
uniform float u_granulation_amp : hint_range(0.0, 1.0) = 0.30;
uniform float u_flicker_intensity : hint_range(0.0, 0.3) = 0.05;
uniform float u_faculae_intensity : hint_range(0.0, 1.0) = 0.5;

uniform vec3 u_core_0 = vec3(1.0, 0.95, 0.8);
uniform vec3 u_core_1 = vec3(1.0, 0.7, 0.2);
uniform vec3 u_core_2 = vec3(0.8, 0.3, 0.05);

uniform int   u_spot_count : hint_range(0, 8) = 0;
uniform vec2  u_spot_pos[8];
uniform float u_spot_size[8];
uniform float u_spot_strength[8];

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
	for (int i = 0; i < 5; i++) {
		v += a * smooth_noise(p * f + time * 0.35 * float(i + 1));
		f *= 2.0;
		a *= 0.5;
	}
	return v;
}

float ridged(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	float f = 1.0;
	for (int i = 0; i < 4; i++) {
		float n = 1.0 - abs(smooth_noise(p * f + time * 0.32 * float(i + 1)) * 2.0 - 1.0);
		v += a * n * n;
		f *= 2.0;
		a *= 0.5;
	}
	return v;
}

float granulation(vec2 p) {
	vec2 q = vec2(fbm(p + time * 0.18), fbm(p + vec2(5.2, 1.3) + time * 0.22));
	vec2 r = vec2(fbm(p + 1.6 * q + vec2(1.7, 9.2) + time * 0.26),
	              fbm(p + 1.6 * q + vec2(8.3, 2.8) + time * 0.30));
	return mix(fbm(p + 1.8 * r), ridged(p + 1.8 * r), 0.6);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Godot canvas_item fragment() disallows mid-function return; wrap
	// the entire body in a single if/else so the shader compiles cleanly.
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv = UV * 2.0 - 1.0;
		float r2 = min(dot(uv, uv), 1.0);
		float mu = sqrt(1.0 - r2);
		float edge_aa = 1.0 - smoothstep(0.97, 1.0, dot(UV * 2.0 - 1.0, UV * 2.0 - 1.0));

		float limb = (1.0 + 1.5 * mu) / 2.5;
		limb = mix(1.0, limb, u_limb_strength);

		float lat = asin(clamp(uv.y, -1.0, 1.0));
		float lon = atan(uv.x, mu);
		vec2 surf = vec2(lon, lat) * u_granulation_scale * 2.5;
		float g = granulation(surf);
		float gc = smoothstep(0.25, 0.75, g);
		float gran_dark = 1.0 - u_granulation_amp;
		float gran_bright = 1.0 + u_granulation_amp * 0.5;

		vec3 p = vec3(uv.x, uv.y, mu);
		float spot_darken = 0.0;
		for (int i = 0; i < 8; i++) {
			if (i >= u_spot_count) break;
			float slat = u_spot_pos[i].x;
			float slon = u_spot_pos[i].y;
			vec3 sp = vec3(cos(slat) * sin(slon), sin(slat), cos(slat) * cos(slon));
			float d = dot(p, sp);
			float ang = acos(clamp(d, -1.0, 1.0));
			float sr = u_spot_size[i];

			// Distort the spot boundary with domain noise so the silhouette
			// is irregular (real sunspots are not perfect circles). Sample
			// noise in the surface frame of the spot so distortion doesn't
			// swim across the disk as the spot drifts.
			float spot_noise = smooth_noise(vec2(ang * 8.0, float(i) * 7.3 + slat * 3.1));
			float noisy_sr = sr * (0.75 + 0.5 * spot_noise);

			if (ang < noisy_sr) {
				// Soft, gradual umbra/penumbra profile: pen depth grows smoothly
				// from 0 at the rim to max at the center. No hard inner edge.
				float t_norm = ang / noisy_sr;  // 0 at center, 1 at rim
				// Penumbra: t ~ 0.5 to 1.0 -> darken 0.20 to 0.
				// Umbra:    t ~ 0.0 to 0.5 -> darken 0.55 to 0.20.
				// Combined gives a smooth radial profile, no step.
				float pen = smoothstep(1.0, 0.5, t_norm);
				float umbra_t = smoothstep(0.5, 0.0, t_norm);
				float depth = mix(0.20, 0.55, umbra_t) * pen;
				depth *= u_spot_strength[i];

				// Soft penumbral edge so the rim fades gently into the photosphere.
				float edge = smoothstep(noisy_sr, noisy_sr * 0.85, ang);
				// Smooth limb fade so spots rotate in/out without popping.
				float limb_fade = smoothstep(0.0, 0.30, d);
				spot_darken = max(spot_darken, depth * edge * limb_fade);
			}
		}

		float fac = 0.0;
		if (u_faculae_intensity > 0.0) {
			float fn = ridged(uv * 18.0 + time * 0.4);
			float limb_mask = pow(1.0 - mu, 3.0);
			fac = pow(fn, 2.0) * limb_mask * u_faculae_intensity * 0.20;
		}

		float ramp_t = 1.0 - mu;
		vec3 photosphere;
		if (ramp_t < 0.5) {
			photosphere = mix(u_core_0, u_core_1, ramp_t * 2.0);
		} else {
			photosphere = mix(u_core_1, u_core_2, (ramp_t - 0.5) * 2.0);
		}

		float flicker = (fbm(uv * 6.0 + time * 0.7) - 0.5) * u_flicker_intensity;
		flicker += (ridged(uv * 16.0 + time * 1.4) - 0.5) * u_flicker_intensity * 0.5;

		vec3 granulated = mix(photosphere * gran_dark, photosphere * gran_bright, gc);

		vec3 col = granulated;
		col *= limb;
		col += flicker * photosphere;
		col *= (1.0 - spot_darken);
		col += fac * photosphere;
		col = clamp(col, 0.0, 1.5);

		COLOR = vec4(col, tex.a * edge_aa);
	}
}