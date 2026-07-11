shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 8.0) = 0.0;
uniform float tiles : hint_range(1.0, 10.0) = 4.0;

void fragment() {
	vec2 uv = fract(UV * tiles);
	vec4 col = texture(TEXTURE, uv);
	if (blur_amount < 0.01 || col.a < 0.001) {
		COLOR = col;
	} else {
		vec2 ps = TEXTURE_PIXEL_SIZE;
		vec4 sum = col; float total = 1.0;
		for (int i = 1; i <= 5; i++) {
			float f = float(i) / 5.0;
			float dist = f * blur_amount;
			float w = exp(-dist * dist * 3.0);
			vec2 o = vec2(dist, 0.0) * ps;
			sum += texture(TEXTURE, uv + vec2( o.x,  o.x)) * w;
			sum += texture(TEXTURE, uv + vec2(-o.x,  o.x)) * w;
			sum += texture(TEXTURE, uv + vec2( o.x, -o.x)) * w;
			sum += texture(TEXTURE, uv + vec2(-o.x, -o.x)) * w;
			total += 4.0 * w;
		}
		COLOR = sum / total;
	}
}
