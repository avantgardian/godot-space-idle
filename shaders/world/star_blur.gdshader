shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 8.0) = 0.0;
uniform float tiles : hint_range(1.0, 10.0) = 4.0;
uniform float time : hint_range(0.0, 1000.0) = 0.0;
uniform float twinkle_strength : hint_range(0.0, 1.0) = 1.0;

// 4 points on a disc — Poisson-ish circular bokeh, halved from 8 taps
// to save ~50% fetches; per-pixel hash rotation keeps it smooth (#296).
const vec2 DISC[4] = vec2[4](
	vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0)
);

float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = fract(UV * tiles);
	vec4 col = texture(TEXTURE, uv);

	if (col.a < 0.001) {
		COLOR = col;
	} else {
		// Depth-of-field: circular bokeh disc. Reduced radius + alpha-weighted
		// sampling so high blur doesn't mix distant stars into a grey wash or
		// spawn 8-point ghosts. Per-pixel rotation breaks the uniform pattern.
		if (blur_amount >= 0.01) {
			vec2 ps = TEXTURE_PIXEL_SIZE;
			float r = blur_amount * 0.42;
			// Per-pixel rotation from hash — breaks the 8-point ghost pattern
			// without adding samples.
			float ang = hash12(floor(uv * 512.0)) * 6.28318;
			float ca = cos(ang);
			float sa = sin(ang);
			// Alpha-weighted accumulation preserves star hue: transparent
			// neighbours contribute zero weight instead of pulling toward black.
			vec4 acc = col;
			float wsum = 1.0;
			for (int i = 0; i < 4; i++) {
				float ring = (i < 2) ? 0.55 : 0.95;
				vec2 d = DISC[i];
				vec2 rd = vec2(d.x * ca - d.y * sa, d.x * sa + d.y * ca);
				vec2 off = rd * r * ring * ps * 10.0;
				vec4 s = texture(TEXTURE, uv + off);
				float w = exp(-ring * ring * 1.6) * 0.38 * s.a;
				acc += s * w;
				wsum += w;
			}
			// Second tighter ring for a creamier bokeh (for larger blur values)
			if (blur_amount > 1.8) {
				float r2 = r * 0.35;
				for (int i = 0; i < 2; i++) {
					vec2 d = DISC[i];
					vec2 rd = vec2(d.x * ca - d.y * sa, d.x * sa + d.y * ca);
					vec2 off = rd * r2 * ps * 10.0;
					vec4 s = texture(TEXTURE, uv + off);
					float w = 0.18 * s.a;
					acc += s * w;
					wsum += w;
				}
			}
			col = acc / wsum;
			col.a *= clamp(1.0 - blur_amount * 0.06, 0.65, 1.0);
		}

		// Twinkle: gentle breathing on bright stars only — faint sheet stays
		// stable. Scintillation is atmospheric; in space stars don't twinkle.
		// Depth/speed are deliberately shallow & slow, masked by luma so only
		// photogenic bright stars (halo/spike population) breathe at all.
		// Twinkle disabled for dust (twinkle_strength == 0).
		if (twinkle_strength > 0.01) {
			// Quantize UV to approx star cell so each star breathes coherently
			// rather than per-pixel shimmer.
			vec2 cell = floor(uv / TEXTURE_PIXEL_SIZE / 3.0);
			float h = hash12(cell);
			float phase = h * 6.28318;
			float speed = 0.45 + h * 0.65;
			float depth = 0.04 + h * 0.07;
			float tw = sin(time * speed + phase) * depth * twinkle_strength;
			// Luma mask: only stars above ~0.28 luma breathe visibly;
			// dim background sheet stays steady.
			float luma = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
			float mask = smoothstep(0.28, 0.58, luma);
			col.rgb *= 1.0 + tw * mask;
			col.a *= 1.0 + tw * mask * 0.55;
		}

		COLOR = col;
	}
}
