shader_type canvas_item;
render_mode unshaded;

// Driven each frame by OrbitalBody._process.
uniform float u_time = 0.0;
uniform vec3  u_light_dir = vec3(1.0, 0.0, 0.0);   // world-space, normalized, points planet -> sun

// Set once per-instance in OrbitalBody._apply_planet_shader from @export fields.
uniform float u_ambient   : hint_range(0.0, 0.5) = 0.06;
uniform float u_limb      : hint_range(0.0, 1.0) = 0.35;
uniform float u_axial_tilt = 0.0;                   // radians
uniform float u_spin_rate = 0.05;                   // rad/s of surface texture "spin"
uniform int   u_seed = 1;

// Biome identity. Per-type issues (#104-#109) override these with biome-specific
// noise + extra uniforms layered on top.
uniform vec3  u_base_color  = vec3(0.5);
uniform float u_noise_scale = 4.0;
uniform float u_noise_amp   : hint_range(0.0, 1.0) = 0.15;

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
		float noise_val = fbm(vec2(lon, lat) * u_noise_scale + seed_off);

		// Base color tinted +/- u_noise_amp by the fbm value.
		vec3 base = mix(u_base_color * (1.0 - u_noise_amp),
		                u_base_color * (1.0 + u_noise_amp),
		                noise_val);

		// Lambert diffuse; ambient floor keeps the night side readable.
		vec3 L = normalize(u_light_dir);
		float diff = max(dot(normalize(n), L), 0.0);
		float lighting = mix(u_ambient, 1.0, diff);

		// Limb darkening (matches sun_surface.gdshader form).
		float limb = (1.0 + 1.5 * mu) / 2.5;
		limb = mix(1.0, limb, u_limb);

		vec3 col = base * lighting * limb;
		COLOR = vec4(col, tex.a * edge_aa);
	}
}