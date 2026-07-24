shader_type canvas_item;
render_mode unshaded, blend_add;

// Driven each frame by OrbitalBody._process (kept in sync with the surface
// shader's u_light_dir so the day-side limb always faces the sun).
uniform vec3  u_light_dir = vec3(1.0, 0.0, 0.0);

// Per-instance (set in OrbitalBody._apply_atmosphere_shader).
uniform vec3  u_atm_color        = vec3(0.4, 0.65, 1.0);
uniform float u_atm_intensity    : hint_range(0.0, 4.0) = 1.2;
uniform float u_atm_ambient      : hint_range(0.0, 1.0) = 0.05;
uniform float u_atm_thickness    : hint_range(0.01, 1.0) = 0.03;  // outward halo falloff in UV units (tight = hugging limb)
uniform float u_planet_radius_uv : hint_range(0.1, 1.0) = 0.8;    // planet disk radius in this sprite's UV (1 / atm_thickness_mult)

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv = UV * 2.0 - 1.0;
		float r = length(uv);

		// Day-side weight: largest at the limb on the sun-ward half, zero on
		// the night half.
		vec3 L = normalize(u_light_dir);
		float day_weight = max(dot(normalize(vec3(uv, 0.0)), L), 0.0);

		// Halo kernel: smooth falloff that BEGINS at the planet disk edge
		// (r = u_planet_radius_uv) and decays outward. The bright peak sits
		// just outside the planet's silhouette so the halo envelops the disk
		// instead of cutting a ring around it. Inside the disk we leave the
		// planet sprite alone (the additive rim is 0 there, so the planet's
		// own surface shader shows through unmodified).
		float rim = 0.0;
		if (r > u_planet_radius_uv) {
			float dr = r - u_planet_radius_uv;
			// e^-dr/thickness -> smooth halo. Tight thickness keeps the glow
			// hugging the limb like a real thin atmosphere rather than
			// dispersing far into space.
			rim = exp(-dr / u_atm_thickness);
		}

		// Day/ambient mix.
		float alpha_mult = mix(u_atm_ambient, 1.0, day_weight);
		float alpha = rim * alpha_mult * u_atm_intensity;

		COLOR = vec4(u_atm_color, alpha * tex.a);
	}
}