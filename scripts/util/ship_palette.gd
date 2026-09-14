class_name ShipPalette
extends RefCounted

# ---------------------------------------------------------------------------
# Gritty industrial ship palette. Realism-side, sibling to PlanetPalette.
# Stranded tug / Belter workhorse: worn paint, bare aluminum, soot, primer.
# See plans/spaceship-gritty-redesign.md for design language.
# ---------------------------------------------------------------------------

# Hull — worn white paint over steel (main plates).
const HULL_PAINT: Color = Color(0.78, 0.78, 0.76, 1.0)
const HULL_PAINT_SHADOW: Color = Color(0.52, 0.52, 0.51, 1.0)
const HULL_PANEL_LINE: Color = Color(0.09, 0.09, 0.10, 0.55)

# Exposed metal — where paint has chipped or been stripped.
const METAL_ALUMINUM: Color = Color(0.72, 0.73, 0.74, 1.0)
const METAL_ALUMINUM_HI: Color = Color(0.92, 0.93, 0.94, 1.0)
const METAL_DARK: Color = Color(0.22, 0.23, 0.25, 1.0)
const METAL_DARK_HI: Color = Color(0.32, 0.33, 0.35, 1.0)
const PRIMER_RED: Color = Color(0.52, 0.20, 0.14, 1.0)
const SOOT_DARK: Color = Color(0.08, 0.07, 0.07, 1.0)
const SOOT_MID: Color = Color(0.18, 0.16, 0.14, 1.0)

# Cockpit glass — cold, slightly reflective.
const GLASS_TINT: Color = Color(0.55, 0.68, 0.72, 0.82)
const GLASS_TINT_SHADOW: Color = Color(0.22, 0.28, 0.30, 0.85)
const GLASS_SPEC: Color = Color(0.95, 0.98, 1.0, 0.95)
const COCKPIT_INTERIOR: Color = Color(0.08, 0.11, 0.13, 1.0)
const COCKPIT_INTERIOR_LIT: Color = Color(0.16, 0.20, 0.18, 1.0)
const COCKPIT_GLOW: Color = Color(0.35, 0.42, 0.38, 0.45)

# Engine plume — hot core -> blue -> soot orange.
const ENGINE_CORE: Color = Color(0.96, 0.98, 1.0, 1.0)
const ENGINE_MID: Color = Color(0.40, 0.72, 1.0, 0.95)
const ENGINE_OUTER: Color = Color(1.0, 0.52, 0.14, 0.78)
const ENGINE_OUTER_DIM: Color = Color(0.55, 0.28, 0.08, 0.35)
const NOZZLE_INNER: Color = Color(0.85, 0.45, 0.18, 1.0)
const NOZZLE_THROAT: Color = Color(0.98, 0.96, 0.88, 1.0)

# Nav / running lights (diegetic highlight, replaces neon ring).
const NAV_RED: Color = Color(1.0, 0.15, 0.15, 1.0)
const NAV_RED_DIM: Color = Color(0.55, 0.08, 0.08, 0.45)
const NAV_GREEN: Color = Color(0.18, 0.95, 0.32, 1.0)
const NAV_GREEN_DIM: Color = Color(0.10, 0.45, 0.16, 0.45)
const NAV_WHITE: Color = Color(0.92, 0.92, 0.88, 1.0)
const NAV_WHITE_DIM: Color = Color(0.40, 0.40, 0.38, 0.35)
const WARNING_STRIPE: Color = Color(0.92, 0.72, 0.08, 1.0)
const WARNING_STRIPE_DARK: Color = Color(0.18, 0.16, 0.08, 1.0)

# Ambient / lighting tuning (matches orbital_body ambient but slightly higher for readability).
const SHIP_AMBIENT: float = 0.32

# Specular tuning for aluminum chamfers / glass.
const SPEC_POWER_ALU: float = 42.0
const SPEC_POWER_GLASS: float = 64.0
const SPEC_INTENSITY_ALU: float = 0.55
const SPEC_INTENSITY_GLASS: float = 0.85
