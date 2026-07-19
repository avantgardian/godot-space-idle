class_name DrawUtils
extends RefCounted

const PAL := preload("res://scripts/tron_palette.gd")

# ---------------------------------------------------------------------------
# TRON neon rendering helpers. Pure-draw utilities; callers own state
# (pulsation, animation phases) and pass already-modulated colors in so the
# helper has no hidden time dependence. See AGENTS.md "Visual language".
# ---------------------------------------------------------------------------

# Canonical 3-stroke neon widths. The triple-stack IS the TRON look:
# wide soft glow -> mid stroke -> crisp inner core.
const NEON_GLOW_WIDTH   := 5.0
const NEON_LINE_WIDTH   := 1.5
const NEON_BRIGHT_WIDTH := 0.5

# 2-stroke accent widths (filled polygon + glowing outline + crisp edge).
const ACCENT_GLOW_WIDTH := 2.0
const ACCENT_LINE_WIDTH := 0.5

# Default per-arc sampling resolution. Higher = smoother curved strokes.
const ARC_RESOLUTION := 18

# Orbit trail tint + alpha tuning (issue #85).
# 2-stop cyan gradient: head = HULL_BRIGHT tinted toward the planet's
# identity color (gradient stop 1, the newest end of the trail); tail =
# HULL_LINE tinted toward identity with low alpha (stop 0, oldest end).
# All trails render with additive blending (configured by TrailComponent).
const TRAIL_HEAD_TINT  := 0.55
const TRAIL_HEAD_ALPHA := 0.85
const TRAIL_TAIL_TINT  := 0.35
const TRAIL_TAIL_ALPHA := 0.0


# 3-stroke neon passage. Pass any closed or open polyline; if you want a
# closed outline, ensure `points[length-1] == points[0]` (as the spaceship
# hull does) — `draw_polyline` will not auto-close.
static func neon_polyline(
		canvas: CanvasItem,
		points: PackedVector2Array,
		glow: Color, line: Color, bright: Color,
		antialias: bool = true
) -> void:
	canvas.draw_polyline(points, glow,   NEON_GLOW_WIDTH,   antialias)
	canvas.draw_polyline(points, line,   NEON_LINE_WIDTH,   antialias)
	canvas.draw_polyline(points, bright, NEON_BRIGHT_WIDTH, antialias)


# Single neon arc, 3-stroke. Polyline endpoints are sampled at the supplied
# resolution; use `a1 - a0 == TAU` and `points[0] == points[end]` semantics
# to get a closed circle.
static func neon_arc(
		canvas: CanvasItem,
		center: Vector2, r: float,
		a0: float, a1: float,
		segments: int,
		glow: Color, line: Color, bright: Color,
		antialias: bool = true
) -> void:
	var pts := PackedVector2Array()
	for j in range(segments + 1):
		var a := lerpf(a0, a1, float(j) / float(segments))
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	neon_polyline(canvas, pts, glow, line, bright, antialias)


# Segmented neon ring — N arc segments with symmetric angular gaps. This is
# the canonical TRON HUD-overlay ring (used by the spaceship indicator ring).
# `gap` is the radians of empty space between consecutive arc segments; the
# first arc begins immediately above top (at angle `-PI/2 + gap/2`) so the
# gap pattern is visually symmetric about the heading axis.
static func neon_segmented_ring(
		canvas: CanvasItem,
		center: Vector2, r: float,
		segment_count: int, gap: float,
		glow: Color, line: Color, bright: Color,
		antialias: bool = true
) -> void:
	var arc_len := (TAU - segment_count * gap) / segment_count
	var start := -PI * 0.5 + gap * 0.5
	for i in range(segment_count):
		var a0 := start + (arc_len + gap) * i
		var a1 := a0 + arc_len
		neon_arc(canvas, center, r, a0, a1, ARC_RESOLUTION, glow, line, bright, antialias)


# Full neon circle — closed 360° arc with the 3-stroke stack.
static func neon_circle(
		canvas: CanvasItem,
		center: Vector2, r: float,
		glow: Color, line: Color, bright: Color,
		segments: int = 64,
		antialias: bool = true
) -> void:
	neon_arc(canvas, center, r, 0.0, TAU, segments, glow, line, bright, antialias)


# Filled accent polygon: solid fill + outer glow stroke + crisp inner edge.
# Used for the spaceship wing-trim stripes. Pass a closed point array
# (last point == first) so `draw_polyline` outlines the whole shape.
static func neon_filled_accent(
		canvas: CanvasItem,
		points: PackedVector2Array,
		fill: Color, glow: Color, line: Color,
		antialias: bool = true
) -> void:
	canvas.draw_colored_polygon(points, fill)
	canvas.draw_polyline(points, glow,  ACCENT_GLOW_WIDTH, antialias)
	canvas.draw_polyline(points, line,  ACCENT_LINE_WIDTH, antialias)


# Pulsation envelope: sine swing between `min_val` and 1.0. Use to modulate
# alpha of neon overlays that should "breathe" (e.g., click-me hints).
# `phase` is in radians; the caller advances it at the desired rate.
static func pulsate_factor(phase: float, min_val: float = 0.35) -> float:
	return min_val + (1.0 - min_val) * (sin(phase) * 0.5 + 0.5)


# Multiply a Color's alpha by `factor` while keeping RGB intact. Convenience
# for applying a pulsate_factor to a base TronPalette color.
static func modulate_alpha(c: Color, factor: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * factor)


# ---------------------------------------------------------------------------
# Orbit trail color helpers (issue #85).
# Trails use a 2-stop cyan gradient drawn from TronPalette tokens. To keep
# planets visually distinguishable, the head and tail colors are a lerp from
# the canonical TRON cyan toward the planet's identity color.
# Head = HULL_BRIGHT tinted up to 55% toward planet_color (bright, drawn at
# gradient stop 1 — the newest end of the trail). Tail = HULL_LINE tinted
# 35% toward planet_color with low alpha (gradient stop 0 — the oldest end,
# fades away). All trails render with additive blending (set up by
# TrailComponent), so head brightness stacks against the near-black BG.
static func trail_head(planet_color: Color) -> Color:
	return Color(
		lerpf(PAL.HULL_BRIGHT.r, planet_color.r, TRAIL_HEAD_TINT),
		lerpf(PAL.HULL_BRIGHT.g, planet_color.g, TRAIL_HEAD_TINT),
		lerpf(PAL.HULL_BRIGHT.b, planet_color.b, TRAIL_HEAD_TINT),
		TRAIL_HEAD_ALPHA
	)

static func trail_tail(planet_color: Color) -> Color:
	return Color(
		lerpf(PAL.HULL_LINE.r, planet_color.r, TRAIL_TAIL_TINT),
		lerpf(PAL.HULL_LINE.g, planet_color.g, TRAIL_TAIL_TINT),
		lerpf(PAL.HULL_LINE.b, planet_color.b, TRAIL_TAIL_TINT),
		TRAIL_TAIL_ALPHA
	)