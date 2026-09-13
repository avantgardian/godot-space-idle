shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 8.0) = 0.0;
uniform float tiles : hint_range(1.0, 10.0) = 4.0;
uniform float time : hint_range(0.0, 1000.0) = 0.0;
uniform float twinkle_strength : hint_range(0.0, 1.0) = 1.0;

// 8 points on a disc + cardinals — Poisson-ish circular bokeh.
const vec2 DISC[8] = vec2[8](
	vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
	vec2(0.707, 0.707), vec2(-0.707, 0.707), vec2(0.707, -0.707), vec2(-0.707, -0.707)
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
		// Depth-of-field: circular bokeh disc instead of diagonal streaks.
		if (blur_amount >= 0.01) {
			vec2 ps = TEXTURE_PIXEL_SIZE;
			// Two rings: inner cardinals at 0.55*R, outer diagonals at 0.95*R
			// gives a filled disc with softer edge than a single ring.
			float r = blur_amount * 0.55;
			vec4 acc = col;
			float wsum = 1.0;
			for (int i = 0; i < 8; i++) {
				float ring = (i < 4) ? 0.55 : 0.95;
				vec2 off = DISC[i] * r * ring * ps * 18.0;
				// Gaussian weight falls with ring radius so outer ring contributes less
				float w = exp(-ring * ring * 1.8) * 0.42;
				acc += texture(TEXTURE, uv + off) * w;
				wsum += w;
			}
			// Second tighter ring for a creamier bokeh (for larger blur values)
			if (blur_amount > 2.5) {
				float r2 = r * 0.35;
				for (int i = 0; i < 4; i++) {
					vec2 off = DISC[i] * r2 * ps * 18.0;
					float w = 0.18;
					acc += texture(TEXTURE, uv + off) * w;
					wsum += w;
				}
			}
			col = acc / wsum;
			col.a *= clamp(1.0 - blur_amount * 0.04, 0.55, 1.0);
		}

		// Twinkle: very subtle brightness warble driven by per-star hash,
		// only when twinkle_strength > 0 (disabled for dust + reduced motion).
		if (twinkle_strength > 0.01) {
			// Quantize UV to approx star cell so each star twinkles coherently
			// rather than per-pixel shimmer.
			vec2 cell = floor(uv / TEXTURE_PIXEL_SIZE / 3.0);
			float h = hash12(cell);
			float phase = h * 6.28318;
			float speed = 0.7 + h * 1.1;
			float depth = 0.08 + h * 0.10;
			float tw = sin(time * speed + phase) * depth * twinkle_strength;
			// Only stars above a luma threshold twinkle visibly — dim sheet stays steady.
			float luma = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
			float mask = smoothstep(0.15, 0.45, luma);
			col.rgb *= 1.0 + tw * mask;
			col.a *= 1.0 + tw * mask * 0.6;
		}

		COLOR = col;
	}
}
