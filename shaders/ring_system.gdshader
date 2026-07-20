shader_type canvas_item;
render_mode unshaded;

// Driven each frame by saturn.gd._process.
uniform vec3  u_light_dir = vec3(1.0, 0.0, 0.0);

// Ring geometry (normalized 0..1 in sprite UV space).
uniform float u_ring_inner     : hint_range(0.2, 0.5) = 0.32;
uniform float u_ring_outer     : hint_range(0.4, 0.8) = 0.62;
uniform float u_cassini        : hint_range(0.35, 0.55) = 0.49;
uniform float u_cassini_width   = 0.025;
uniform float u_encke          : hint_range(0.45, 0.60) = 0.55;
uniform float u_encke_width     = 0.006;

// Colors from PlanetPalette.RING_SATURN_*.
uniform vec3  u_ring_bright = vec3(0.78, 0.68, 0.45);
uniform vec3  u_ring_dark   = vec3(0.20, 0.15, 0.08);

// Planet shadow on the ring.
uniform float u_shadow_strength : hint_range(0.0, 1.0) = 0.4;

// Noise seed — matches the planet's u_seed for deterministic look.
uniform int   u_ring_seed = 1;

// Masking. Set by saturn.gd to split front/back ring halves.
// 0 = show full ring, 1 = show only front half (uv.y > 0), -1 = show only back half (uv.y < 0).
uniform int u_half_mask = 0;

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
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Clip to ring annulus — alpha 0 outside.
	float in_ring = step(u_ring_inner - 0.02, r) * (1.0 - step(u_ring_outer + 0.02, r));

	float r_norm = (r - u_ring_inner) / (u_ring_outer - u_ring_inner);

	vec3 ring_col = u_ring_dark;
	ring_col = mix(ring_col, u_ring_bright, smoothstep(0.0, 0.30, r_norm) * in_ring);
	ring_col = mix(ring_col, u_ring_dark, smoothstep(0.55, 0.85, r_norm) * in_ring);

	vec2 seed_off = vec2(float(u_ring_seed) * 1.7, float(u_ring_seed) * 0.93);
	float ring_noise = fbm(vec2(r * 30.0, 0.5) + seed_off);
	ring_col = mix(ring_col, ring_col * (0.88 + ring_noise * 0.24), 0.45 * in_ring);

	float c_lo = u_cassini - u_cassini_width * 0.5;
	float c_hi = u_cassini + u_cassini_width * 0.5;
	float cassini_gap = smoothstep(c_lo - 0.004, c_lo, r)
	                  * (1.0 - smoothstep(c_hi, c_hi + 0.004, r));
	ring_col = mix(ring_col, ring_col * 0.08, cassini_gap);

	float e_lo = u_encke - u_encke_width * 0.5;
	float e_hi = u_encke + u_encke_width * 0.5;
	float encke_gap = smoothstep(e_lo - 0.002, e_lo, r)
	                * (1.0 - smoothstep(e_hi, e_hi + 0.002, r));
	ring_col = mix(ring_col, ring_col * 0.15, encke_gap);

	vec2 light_2d = normalize(u_light_dir.xy);
	float dot_l = dot(normalize(uv), light_2d);
	float shadow = smoothstep(0.2, -0.2, dot_l);
	ring_col *= (1.0 - shadow * u_shadow_strength);

	float edge = smoothstep(u_ring_inner - 0.015, u_ring_inner, r)
	           * (1.0 - smoothstep(u_ring_outer, u_ring_outer + 0.015, r));

	float alpha = edge * (1.0 - cassini_gap * 0.9) * in_ring;

	// Half-mask for front/back ring sprites. The ring is a flat disk;
	// splitting along the local Y axis gives a believable front/back
	// illusion when the front sprite is at z=1 and the back at z=-1.
	if (u_half_mask == 1 && uv.y < 0.0) {
		alpha = 0.0;   // front sprite: clip back half
	} else if (u_half_mask == -1 && uv.y > 0.0) {
		alpha = 0.0;   // back sprite: clip front half
	}

	alpha = clamp(alpha, 0.0, 1.0);
	COLOR = vec4(ring_col * alpha, alpha);
}
