shader_type canvas_item;

// TRON grid plane — repeating cyan lines over the near-black BG.
// Used by scenes/main_menu.tscn as a subtle background grid.
// Color/spacing tunables live here; pull colors from TronPalette by
// setting the matching shader_parameter from GDScript if needed.

uniform vec4 line_color : source_color = vec4(0.18, 0.55, 1.0, 0.08);
uniform float cell_size  : hint_range(8.0, 256.0) = 50.0; // px between lines
uniform float line_width : hint_range(0.5, 4.0) = 1.0;   // px

// Returns 1.0 on a grid line, 0.0 between lines, with a smooth falloff.
float grid_axis(float coord) {
	float half_cell = cell_size * 0.5;
	float m = mod(coord, cell_size);
	float d = abs(m - half_cell) - (half_cell - line_width);
	return 1.0 - smoothstep(0.0, line_width, max(d, 0.0));
}

void fragment() {
	vec2 px = SCREEN_UV * SCREEN_PIXEL_SIZE;
	float g = max(grid_axis(px.x), grid_axis(px.y));
	COLOR = vec4(line_color.rgb, line_color.a * g);
}