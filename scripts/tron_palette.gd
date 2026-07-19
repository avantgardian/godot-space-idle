class_name TronPalette
extends RefCounted

# ---------------------------------------------------------------------------
# TRON design language tokens. Single source of truth for all neon rendering.
# See AGENTS.md "Visual language" section for usage rules.
# ---------------------------------------------------------------------------

# World background (near-black navy). Used by main.gd, progression.gd,
# main_menu.tscn, game_theme.tres panel bg.
const BG := Color(0.0392, 0.0392, 0.102)

# Cyan primary family — used for hull strokes, rings, wireframe elements.
# The 3-stroke triple-stack is: HULL_GLOW (wide/soft) -> HULL_LINE (mid) ->
# HULL_BRIGHT (crisp core). See DrawUtils.neon_polyline.
const HULL_GLOW   := Color(0.18, 0.55, 1.00, 0.45)
const HULL_LINE   := Color(0.55, 0.95, 1.00, 1.00)
const HULL_BRIGHT := Color(0.92, 1.00, 1.00, 1.00)

# Orange accent family — used for wing trims, asteroid strokes, sun crowns,
# thrust highlights. Same 3-stack recipe uses ACCENT_GLOW + ACCENT.
const ACCENT      := Color(1.00, 0.55, 0.15, 1.00)
const ACCENT_GLOW := Color(1.00, 0.45, 0.10, 0.55)

# Cockpit core — bright diamond + soft halo underlayer.
const COCKPIT      := Color(0.92, 1.00, 1.00, 1.00)
const COCKPIT_GLOW := Color(0.25, 0.75, 1.00, 0.55)

# Engine exhaust — additive teal jet flame.
const ENGINE_PORT  := Color(0.20, 0.60, 1.00, 0.55)
const PORT_CORE    := Color(0.85, 1.00, 1.00, 0.90)
const FLAME_OUTER  := Color(0.10, 0.60, 1.00, 0.95)
const FLAME_INNER  := Color(0.85, 1.00, 1.00, 0.95)

# Indicator ring / HUD-overlay family. Alpha is capped at RING_ALPHA_MAX to
# keep these elements reading as GUI overlays rather than hull structure
# (PR #80 rule). Pulsation swings alpha between RING_PULSE_MIN and 1.0 of
# the capped values at RING_PULSE_SPEED rad/s.
const RING_GLOW       := Color(0.18, 0.55, 1.00, 0.15)
const RING_LINE       := Color(0.45, 0.95, 1.00, 0.475)
const RING_BRIGHT     := Color(0.85, 1.00, 1.00, 0.50)
const RING_ALPHA_MAX  := 0.5
const RING_PULSE_MIN  := 0.35
const RING_PULSE_SPEED := 2.5