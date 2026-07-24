class_name PlanetPalette
extends RefCounted

# ---------------------------------------------------------------------------
# Realism-side planet biome palette. Single source of truth for the
# photometric surface colors of celestial bodies (planets, moons, ring
# particles, atmosphere rims). Sibling to TronPalette: TRON tokens govern
# GUI chrome / trails / overlays; PlanetPalette governs the bodies
# themselves. See AGENTS.md "Visual language" for the split rationale.
#
# Values are sRGB-ish author-friendly colors meant to be tinted by fbm
# noise in the planet shaders. Calibrate live in the Godot editor against
# the sun at the same orbit radius if a biome reads off.
# ---------------------------------------------------------------------------

# Rocky biome — Mercury, Mars, dead moons, dry asteroids.
const ROCKY_MERCURY_HI    := Color(0.62, 0.58, 0.55, 1.0)
const ROCKY_MERCURY_LO    := Color(0.30, 0.27, 0.25, 1.0)
const ROCKY_MARS_HI      := Color(0.85, 0.40, 0.20, 1.0)
const ROCKY_MARS_LO      := Color(0.45, 0.18, 0.10, 1.0)
const ROCKY_MARS_ICE     := Color(0.90, 0.85, 0.80, 1.0)
const ROCKY_CRATER_SHADOW := Color(0.0, 0.0, 0.0, 0.0)

# Greenhouse biome — Venus, hot thick cloud decks.
const VENUS_CLOUD_HI     := Color(0.95, 0.85, 0.55, 1.0)
const VENUS_CLOUD_LO     := Color(0.65, 0.45, 0.20, 1.0)
const VENUS_SURFACE_LAVA := Color(0.60, 0.15, 0.05, 1.0)

# Terrestrial biome — Earth, habitable worlds.
const TERRA_OCEAN_DEEP   := Color(0.04, 0.18, 0.42, 1.0)
const TERRA_OCEAN_SHALLOW := Color(0.10, 0.45, 0.65, 1.0)
const TERRA_LAND_TROPICAL := Color(0.10, 0.45, 0.15, 1.0)
const TERRA_LAND_DESERT  := Color(0.78, 0.65, 0.40, 1.0)
const TERRA_LAND_TUNDRA  := Color(0.55, 0.55, 0.40, 1.0)
const TERRA_ICE_CAP      := Color(0.92, 0.95, 1.00, 1.0)
const TERRA_CLOUD_WHITE  := Color(0.95, 0.95, 0.95, 0.85)
const TERRA_OCEAN_SPECULAR := Color(0.95, 0.98, 1.00, 1.0)

# Gas-giant biome — Jupiter (and Saturn band base).
const GAS_BAND_TAN_HI    := Color(0.88, 0.78, 0.55, 1.0)
const GAS_BAND_TAN_LO    := Color(0.50, 0.32, 0.18, 1.0)
const GAS_STORM_RUST     := Color(0.85, 0.30, 0.20, 1.0)
const GAS_STORM_WHITE    := Color(0.95, 0.95, 0.95, 1.0)
const SATURN_BAND_HI     := Color(0.85, 0.75, 0.45, 1.0)
const SATURN_BAND_LO     := Color(0.55, 0.40, 0.22, 1.0)

# Ice-giant biome — Uranus, Neptune, methane-blue worlds.
const ICE_METHANE_BLUE   := Color(0.30, 0.65, 0.85, 1.0)
const ICE_DEEP_BLUE      := Color(0.10, 0.25, 0.65, 1.0)
const ICE_STORM_DARK     := Color(0.04, 0.10, 0.30, 1.0)
const ICE_HAZE_WHITE     := Color(0.85, 0.92, 1.00, 1.0)

# Atmospheric rim glow (cross-biome additive limb sprite, #110).
const ATM_RIM_EARTH      := Color(0.40, 0.65, 1.00, 1.0)
const ATM_RIM_VENUS      := Color(0.95, 0.85, 0.55, 1.0)
const ATM_RIM_MARS       := Color(0.85, 0.55, 0.35, 1.0)
const ATM_RIM_ICE        := Color(0.40, 0.65, 1.00, 1.0)

# Ring system (Saturn-style, #108).
const RING_SATURN_TAN    := Color(0.78, 0.68, 0.45, 1.0)
const RING_SATURN_DARK  := Color(0.20, 0.15, 0.08, 1.0)