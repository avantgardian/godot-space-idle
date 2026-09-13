class_name StellarPalette
extends RefCounted

# ---------------------------------------------------------------------------
# Stellar palette — single source of truth for background star-field colours.
# Sibling to TronPalette (GUI neon) and PlanetPalette (realism bodies).
# Maps Harvard spectral classes OBAFGKM → black-body chromaticity → sRGB.
#
# Research → game conventions
# ──────────────────────────────────────────────────────────────────────────
# OBAFGKM temperatures (ATNF/CSIRO, Harvard): O ≥30kK blue, B 10–30kK
# blue-white, A 7.5–10kK white, F 6–7.5kK yellow-white, G 5.3–6kK yellow,
# K 3.9–5.3kK orange, M 2.3–3.9kK red-orange. Black-body ↔ sRGB via
# CIE 1931 CMF integration (Charity / Ballesteros / starhue), D65 white
# point — see vendian.org/mncharity/dir3/starcolor/, arXiv:2101.06254
# (Pecaut & Mamajek updated PMS, digital color codes of stars).
#
# Solar-neighbourhood IMF (CNS5 / Chabrier): M ~76%, K ~12%, G ~7.6%,
# F ~3%, A ~0.6%, B ~0.12%, O ~0.00003% — overwhelmingly red dwarfs that
# are invisible to the naked eye (M_V > 10). Naked-eye / apparent-magnitude
# limited catalogs (Tycho-2/UCAC4/Gaia, mag < 6–10) look radically bluer:
# luminous OBAFGK giants & upper main sequence dominate because L ∝ M^3.5.
# Empircal bright-star mix ≈ O/B 8–12%, A 15–20%, F 12–15%, G 15–20%,
# K 20–25%, M 10–18% — far redder than true IMF, far bluer than naked eye
# expectation of "mostly white".
#
# Game slimming: keep total background stars sparse (~410, BG_LAYERS in
# star_field.gd) — vary distribution, not count. Expose 7 tints lerped
# from black-body (not pure white); a few very blue / very red outliers
# give the "hot blue, cool red" read without painting the sky red. Bright
# stars are few (power-law magnitude: ~1–2% at m<2, doubling per mag,
# ∝ 10^{0.6m} / dN/dm). Colour–magnitude–size coupling: hotter/brighter
# stars drive slightly larger diffraction discs + bokeh halo; ~5% outliers
# at 1.5–2.2× radius with soft glow. Scintillation is atmospheric — in
# space stars are stable; twinkle is reduced to gentle breathing on bright
# stars only (shader masks by luma, respects reduced_motion).
#
# Token sources:
# - O #9bb0ff, B #aabfff, A #cad7ff, F #f8f7ff, G #fff4ea, K #ffd2a1,
#   M #ff8b3a are the Charity condensed 7-class sRGB values (6300K–30kK
#   black-body, CIE 1931 + sRGB D65), nudged so M reads orange-red rather
#   than pale peach (arXiv:2101.06254 PHOENIX M-dwarf orange, not deep red;
#   hex #ff7d24). All 7 survive at game exposure without blowing out.
# ---------------------------------------------------------------------------

# O — hot blue, ~30–50kK (e.g. 10 Lac, Mintaka). Very rare in field.
const STAR_O_BLUE: Color = Color(0.612, 0.69, 1.0, 1.0)  # #9bb0ff

# B — blue-white, ~10–30kK (Rigel, Spica). Luminous, over-represented
# in apparent-magnitude limited sky vs IMF.
const STAR_B_BLUE_WHITE: Color = Color(0.667, 0.749, 1.0, 1.0)  # #aabfff

# A — white, ~7.5–10kK (Sirius, Vega). Strong Balmer.
const STAR_A_WHITE: Color = Color(0.792, 0.843, 1.0, 1.0)  # #cad7ff

# F — yellow-white, ~6–7.5kK (Canopus, Procyon). White with warm hint.
const STAR_F_WARM_WHITE: Color = Color(0.973, 0.969, 1.0, 1.0)  # #f8f7ff

# G — yellow, ~5.3–6kK (Sun G2V). Solar-type; actually white from space
# (starhue #fff1ea), kept faintly yellow for read vs F.
const STAR_G_YELLOW: Color = Color(1.0, 0.957, 0.918, 1.0)  # #fff4ea

# K — light orange, ~3.9–5.3kK (Arcturus, Aldebaran). Dominant naked-eye orange.
const STAR_K_ORANGE: Color = Color(1.0, 0.824, 0.631, 1.0)  # #ffd2a1

# M — orange-red, ~2.3–3.9kK (Betelgeuse, Antares; Lacaille 8760 dwarfs
# are invisible naked-eye). PHOENIX says orange not deep red — vivid
# outlier tint so occasional M star reads as "red star".
const STAR_M_RED: Color = Color(1.0, 0.545, 0.227, 1.0)  # #ff8b3a

# Ordered array O→M for indexed sampling.
const ORDERED: Array[Color] = [
	STAR_O_BLUE,
	STAR_B_BLUE_WHITE,
	STAR_A_WHITE,
	STAR_F_WARM_WHITE,
	STAR_G_YELLOW,
	STAR_K_ORANGE,
	STAR_M_RED,
]

# Game-biased spectral weights (sum ≈ 1.0) — apparent-magnitude limited
# sky, NOT volume IMF. IMF would be M 76% / K 12% / G 7.6% / F 3% /
# A 0.6% / B 0.12% / O 0.00003% (Encyclopedia / Wikipedia/ATNF). Bright
# sky weights below flatten by luminosity so blue stars are actually seen:
# a handful of hot outliers + warm K/M tail. Tuned so ~35% blue-white
# (OBA), ~35% yellow-orange (GK), ~30% intermediate + red tail.
const WEIGHT_O: float = 0.015
const WEIGHT_B: float = 0.075
const WEIGHT_A: float = 0.150
const WEIGHT_F: float = 0.140
const WEIGHT_G: float = 0.180
const WEIGHT_K: float = 0.250
const WEIGHT_M: float = 0.190

const WEIGHTS: Array[float] = [
	WEIGHT_O,
	WEIGHT_B,
	WEIGHT_A,
	WEIGHT_F,
	WEIGHT_G,
	WEIGHT_K,
	WEIGHT_M,
]


static func sample_spectral_color(rng: RandomNumberGenerator) -> Color:
	var pick: float = rng.randf()
	var acc: float = 0.0
	for i: int in WEIGHTS.size():
		acc += WEIGHTS[i]
		if pick < acc:
			return _jitter_color(rng, ORDERED[i], i)
	return ORDERED[6]


static func _jitter_color(rng: RandomNumberGenerator, base: Color, idx: int) -> Color:
	# Tiny subtype jitter: lerp toward neighbour class ± one step so
	# subclass (e.g. B3 vs B8, K2 vs K5) reads as subtle hue spread,
	# not flat posterized blobs. No extra allocations.
	var t: float = rng.randf_range(-0.28, 0.28)
	if t > 0.0 and idx < ORDERED.size() - 1:
		return base.lerp(ORDERED[idx + 1], t)
	if t < 0.0 and idx > 0:
		return base.lerp(ORDERED[idx - 1], -t)
	return base
