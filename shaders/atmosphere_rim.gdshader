shader_type canvas_item;
render_mode unshaded, blend_add;

// Driven each frame by OrbitalBody._process (kept in sync with the surface
// shader's u_light_dir so the day-side limb always faces the sun).
uniform vec3  u_light_dir = vec3(1.0, 0.0, 0.0);

// Per-instance (set in OrbitalBody._apply_atmosphere_shader).
uniform vec3  u_atm_color        = vec3(0.4, 0.65, 1.0);
uniform float u_atm_intensity    : hint_range(0.0, 4.0) = 1.0;
uniform float u_atm_ambient      : hint_range(0.0, 1.0) = 0.15;
uniform float u_atm_thickness    : hint_range(0.5, 2.0) = 0.07; // half-width of the rim annulus in UV units
uniform float u_atm_outer_falloff: hint_range(0.5, 2.0) = 1.2;  // outward exponential falloff

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.01) {
		COLOR = tex;
	} else {
		vec2 uv = UV * 2.0 - 1.0;
		float r = length(uv);

		// Day-side weight: largest at the limb on the sun-ward half, zero on
		// the night half. Use the normalized pixel direction in view space
		// (z=0 since the rim sprite is a flat 2D plane); this matches the
		// geometry of the planet's lit limb.
		vec3 L = normalize(u_light_dir);
		float day_weight = max(dot(normalize(vec3(uv, 0.0)), L), 0.0);

		// Rim kernel: peak just outside r = 1.0, falls off inward (so the rim
		// hugs the planet silhouette and not the disk center) and outward.
		// Inner mask is the disk edge itself (we'll let the planet sprite
		// cover the inner half).
		float rim = 0.0;
		if (r > 0.85) {
			// Gaussian centered slightly outside the planet rim.
			float dr = r - 1.0;
			rim = exp(-dr * dr / (u_atm_thickness * u_atm_thickness));
			// Soft fade as we get deep inside the disk so the rim doesn't
			// bleed across the planet face when day_weight is high.
			float inner_fade = smoothstep(0.85, 0.99, r);
			rim *= inner_fade;
		}
		// Outer exponential tail so the glow extends past the disk.
		if (r > 1.0) {
			float outer = exp(-(r - 1.0) / u_atm_outer_falloff);
			rim = max(rim, outer * 0.6);
		}

		// Mix between ambient floor and full intensity based on day side.
		float alpha_mult = mix(u_atm_ambient, 1.0, day_weight);
		float alpha = rim * alpha_mult * u_atm_intensity;

		COLOR = vec4(u_atm_color, alpha * tex.a);
	}
}