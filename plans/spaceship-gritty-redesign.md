# Spaceship Gritty Redesign — Plan

> Branch: `issue-spaceship-gritty-redesign` (new, off `main`)
> Status: **planning only** — no code changed yet
> Author: Muse Spark, 2026-09-14

## 1. Problem Statement

The current `scripts/components/spaceship.gd:24-247` is a pure TRON vector wireframe:

- 15-pt `PackedVector2Array` hull (`_hull_points`), twin orange `neon_filled_accent` wing trims, cyan diamond cockpit (`_cockpit_points`/`_halo_points`), plus two additive `Node2D` layers (`_GlowLayer` engine, `_RingLayer` segmented ring) via `DrawUtils.neon_*` + `TronPalette`.
- No sun lighting. The hull is self-illuminated `CanvasItemMaterial.BLEND_MODE_ADD`. It reads as a HUD glyph, not a physical object in the same universe as `shaders/world/sun_surface.gdshader` and `shaders/bodies/planet_*.gdshader` which all use Lambert `diff`, Eddington limb, `mu`/`night_rim`, and fbm noise.
- Weightless feel: zero paneling, zero thickness, zero material response. Asteroids already moved to realism (`asteroid_surface.gdshader` with `u_light_dir`, spin, archetype `PlanetPalette` tints) — the ship is now the last neon anachronism.

User direction: *stranded industrial ship, beaten up from a long deep-space journey, gritty, with light reflections off angled surfaces.*

---

## 2. Vision — "The Mule"

**Narrative anchor:** Not a fighter, not a yacht — a *Belter tug*. Think *Nostromo* + *Rocinante* + *Serenity* + Soviet-era Soyuz service module. A 40-year-old workhorse that has been welded, repainted, and patched more times than logged. You are not its pilot — you are its last crew, keeping it alive.

**Keywords:** boxy, welded, riveted, streaked, soot-stained, asymmetric, functional, heavy.

**Scale:** Keep `COLLISION_RADIUS ~14px` (`spaceship.gd:9`) so gameplay constants (`progression.gd:192 barrier`, `272 click radius`, `_GUT` tests) don't break. But add *perceived volume* — the current dart is ~36×22px silhouette; the new hull will be ~34×28px with a chunkier side profile and a distinct forward/aft read so rotation is instantly legible at 3× zoom out.

---

## 3. Design Pillars

| Pillar | Means |
|---|---|
| **Sun-grounded** | Same `u_light_dir = -position.normalized()` as `orbital_body.gd:321` / `asteroid.gd:234`. Hull facets compute `diff = max(dot(facet_normal, L), 0)` every frame. Angled plates pop differently as you orbit — the core ask. |
| **Material truth** | Matte painted steel (low specular, high diffuse) vs bare aluminum edges (sharp specular) vs soot/blackened nozzles (no specular). No `BLEND_MODE_ADD` on hull. Additive only for *emissive* (engine plume, cockpit interior, nav lights). |
| **Beaten up** | Procedural wear, not random. Paint chips on leading edges, carbon scoring aft of thrusters, one slightly bent comms antenna, patch-panel with mismatched rivets, hairline panel seams. |
| **Modular readability** | Forward / Mid / Aft read at a glance, even at `CameraController.min_zoom = 0.3` (`camera_controller.gd:4`). |

---

## 4. Concept Geometry

Top-down (nose = `-Y`, same convention as current `Vector2.UP.rotated(_angle)` in `spaceship.gd:131`):

```
                 ┌─ cockpit cupola (faceted glass, 3 panes, interior dark)
                 │
          ┌──────┴──────┐
          │  ╱◯╲  nose  │  ← chamfered nose cap (separate plate → specular flash)
          │ ╱───╲       │
          │ │   │       │  ← forward hull (painted white/grey, riveted seams)
          │ └───┘       │
    ┌─────┴─────────────┴─────┐  ← dorsal spine / cargo frame (exposed truss)
    │  radiator ──┤ ├─ radiator │  ← twin radiator fins, slightly asymmetrical (one dinged)
    │  [nav]      │ │      [nav]│
    └─────────────┬┬┘
                  ││  ← engine block (darker steel, plumbing, twin bells)
              (◯) ││ (◯)  ← bell nozzles (interior gradient, throat highlight)
               ╲  ││  ╱
```

- **Forward module (nose + cockpit):** Flat-topped, 5-sided nose plate angled ~35° off center. Cockpit cupola is a truncated pyramid (4 panes + top). Glass uses a *screen-space* specular streak (fake, not true reflection — cheap `_draw` line at `dot(view, reflect(L))` peak) + faint interior `Color(0.08,0.12,0.15)` so it reads as deep.
- **Mid hull:** Rectangular box with **beveled chamfers** on the four side edges (the angled surfaces you asked for). Each chamfer is a separate quad with its own normal → when the sun swings, one chamfer flares while the opposite goes to `u_ambient`. This is where the "light reflections from angles" lives — not a shader trick, just flat-shading.
- **Spine:** Exposed I-beam truss down the centerline, breaks up the silhouette, casts a tiny ambient-occlusion shadow onto the hull beneath (drawn as a dark strip at 18% alpha).
- **Aft block:** Bulkhead + twin bells. Bells are drawn as two stacked trapezoids with interior radial gradient (white core → orange throat → soot). Exterior is gunmetal `SHIP_METAL_DARK`.

---

## 5. Palette — `ShipPalette` (new, sibling to `TronPalette`/`PlanetPalette`)

New file: `scripts/util/ship_palette.gd` (`class_name ShipPalette`, `preload` via `res://` per `AGENTS.md`). No `game_theme.tres` mirror needed (ship only, no UI).

| Token | Approx sRGB | Role |
|---|---|---|
| `HULL_PAINT` | `Color(0.78,0.78,0.76)` | Worn white paint — main plates |
| `HULL_PAINT_SHADOW` | `Color(0.55,0.55,0.54)` | Paint in shadow (ambient) |
| `PRIMER_RED` | `Color(0.52,0.20,0.14)` | Exposed primer where paint chipped |
| `METAL_ALUMINUM` | `Color(0.72,0.73,0.74)` | Bare edge / rivet heads (specular) |
| `METAL_DARK` | `Color(0.22,0.23,0.25)` | Engine block, truss |
| `METAL_SOOT` | `Color(0.08,0.07,0.07)` | Nozzle exterior, scorch streaks |
| `GLASS_TINT` | `Color(0.55,0.68,0.72,0.82)` | Cockpit glass base |
| `GLASS_SPEC` | `Color(0.95,0.98,1.0)` | 1-px specular streak |
| `ENGINE_CORE` | `Color(0.95,0.98,1.0)` | Plume core |
| `ENGINE_MID` | `Color(0.40,0.72,1.0)` | Plume mid (blue) |
| `ENGINE_OUTER` | `Color(1.0,0.55,0.15,0.70)` | Plume outer (soot orange) |
| `NAV_RED` / `NAV_GREEN` | `Color(1,0.15,0.15)` / `Color(0.15,1,0.35)` | Port / starboard running lights |
| `WARNING_STRIPE` | `Color(0.92,0.72,0.08)` | Aft bulkhead hazard chevron |

All `Color` literals live only in `ShipPalette` — `spaceship.gd` must not inline new colors (same rule as `TronPalette`/`PlanetPalette`).

---

## 6. Rendering Architecture — Recommendation: **CPU flat-shaded `_draw` (no new shader)**

### Why not a `canvas_item` shader?

- Planet/asteroid shaders rely on *spherical* `sphere_projection()` (`_planet_common.gdshaderinc:10`) + spin + `mu` limb — wrong for a boxy ship.
- A bespoke `ship_hull.gdshader` with a normal map would be more physically correct (true per-pixel `dot(n, L)` + `pow(dot(H,n), spec_power)`), but requires: (a) authoring a normal map texture or generating one in `TextureUtils`, (b) syncing `u_light_dir` via `ShaderMaterial` each frame (already done for planets/asteroids, so not hard, but adds a draw call + shader compile gate), (c) still needs hand-painted wear.
- `_draw` polygon fills are already how `orbital_body.gd` fallback and `rocket.gd:124` work, so no new pipeline.

### Chosen: CPU per-facet diffuse + fake specular in `_draw`

For each hull polygon (store as `PackedVector2Array` + a `Vector2 facet_normal` in local space), every `_physics_process` or `_process`:

```gdscript
var L_world: Vector2 = -_pos.normalized()  # sun at origin, same as OrbitalBody
var L_local: Vector2 = L_world.rotated(-_angle)  # into ship local
for facet in _facets:
    var ndotl: float = max(facet.normal.dot(L_local), 0.0)
    var lit: Color = SHIP.HULL_PAINT.lerp(SHIP.HULL_PAINT_SHADOW, 1.0 - ndotl) # or mix via `lerp` + ambient
    # + cheap specular on aluminum chamfers: specular = pow(max(dot(H, n),0), 48) * sun_side
```

- **Panel seams:** thin dark lines (`Color(0,0,0,0.35)`, width 0.7px) inset 1px from plate edges.
- **Rivets:** tiny `draw_circle` at seam intersections, `METAL_ALUMINUM` with a 1-px highlight dot offset toward `L_local`.
- **Scorch:** extra `draw_colored_polygon` soot streaks aft of nozzles, feathered alpha, not affected by `L`.
- **Specular flash on chamfers:** when `ndotl > 0.85`, draw a 0.9px `GLASS_SPEC` / `METAL_ALUMINUM` line along the chamfer edge (Blinn-Phong fake). This sells "angled surface catches sun" without a shader.

**Perf:** Same `_draw` batch as now (no new `Sprite2D`/`ShaderMaterial` instantiation in the common case). One optional `ShaderMaterial` only if we want a subtle cockpit glass shader later — deferred to phase 5.

**Additive layers retained but restyled:**

| Old (`_GlowLayer`/`_RingLayer`) | New |
|---|---|
| `_GlowLayer` engine ports + `FLAME_OUTER/INNER` quads (`spaceship.gd:254-296`) | `_EnginePlumeLayer: Node2D` — 3-layer plume (core/mid/outer) with fbm-ish `sin(_phase + hash)*` length jitter, no longer additive cyan but hot white→blue→orange. Still `BLEND_MODE_ADD` because plume *is* emissive. |
| `_RingLayer` segmented neon `RING_*` at 0.5 alpha (`spaceship.gd:299-334`) | `_MarkerLayer: Node2D` — **muted industrial indicator**: 60% smaller, safety-amber `WARNING_STRIPE` at 0.22 alpha, dashed (4 gaps) only when `not input_active` (unselected). When following (`input_active==true`), ring fades out and instead 2 nav lights blink (port red 1.1s, starboard green 1.1s offset). Keeps click affordance without reintroducing TRON. |
| `Pulsate` via `DrawUtils.pulsate_factor` | Kept for nav blink only (`sin` phase), not for ring alpha swing. |

---

## 7. Beaten-Up Storytelling (Procedural, Seed-Stable)

Seed from `planet_seed`-style: `var ship_seed: int = 1337` (or `star_seed ^ 0x9e37`), hashed per feature so the wear is deterministic across runs but looks hand-placed.

- **Paint chips:** 18–24 tiny `PRIMER_RED` + `METAL_DARK` triangles on leading edges (nose, radiator tips, chamfers facing ram direction). Generated once in `_ready` via `RandomNumberGenerator(seed)`.
- **Streaks:** 3 vertical `METAL_SOOT` streaks down the mid hull (grime washed aft), drawn as low-alpha `Polygon2D`-ish quads.
- **One bent antenna:** dorsal whip antenna `draw_line` with a 8° kink at 60% height + a tiny `draw_circle` tip. Pure silhouette story.
- **Mismatched panel:** one mid-hull plate slightly different hue (`HULL_PAINT * 0.92`) with extra rivets — suggests a field repair.
- **Window micro-scratches:** when sun is at grazing angle, a faint `GLASS_SPEC` cross-hatch (2 lines at 20% alpha) appears on cockpit — cheap but effective.

All wear is `_draw` geometry, not texture — keeps the "every pixel authored" feel consistent with `TextureUtils.make_disk_mask` approach elsewhere.

---

## 8. Rocket Restyle (to match)

`scripts/components/rocket.gd:16-19,116-130` currently shares the same neon dart (`PAL.ACCENT`). Should become a stubby **torpedo / probe**:

- Body: gunmetal cylinder + 3 small fins, nose in `HULL_PAINT` with `WARNING_STRIPE` band.
- Trail: `TrailComponent` already used (`rocket.gd:71-77`) — keep but retint from `ACCENT` orange to `ENGINE_MID/OUTER` so rocket and ship plumes share the same fire language.
- Keep `DU.neon_polyline` removal — rocket will also be flat-shaded with a tiny sun `diff` so it doesn't glow in shadow.

Low risk; can be done after ship lands or in same PR behind a feature flag.

---

## 9. File / Change Map

| File | Action | Notes |
|---|---|---|
| `scripts/util/ship_palette.gd` | **NEW** | 12 tokens above, `class_name ShipPalette extends RefCounted` |
| `scripts/components/spaceship.gd` | **REWRITE** (~70% churn) | Keep public API (`mass`, `collision_radius`, `input_active`, `init`, `_physics_process` movement, `try_fire`, `enforce_sun_barrier`, `is_alive/is_dead`, `get_vel/set_vel`, `disable`). Replace all `PAL:=TronPalette` + `DU` neon calls + geometry statics (`_hull_points`, `_accent_*`, `_cockpit/halo`) with `SHIP:=ShipPalette` + new facet arrays + `_EnginePlumeLayer` + `_MarkerLayer`. Add `_update_sun_lighting()` helper. |
| `shaders/bodies/ship_hull.gdshader` | **MAYBE NEW (deferred)** | Only if phase 5 decides per-pixel specular is needed. Not in initial PR. |
| `scripts/components/rocket.gd` | **EDIT** (small) | Swap neon dart for torpedo, retint trail, remove `DU`/`PAL` neon deps. |
| `scripts/controllers/progression.gd` | **NO-OP** | `try_fire` target logic stays. Only visual change flows through. |
| `tests/test_spaceship.gd` (if exists, else new) | **NEW/EDIT** | Assert `collision_radius == 14`, `init` places correctly, `input_active` toggles plume vis, sun lighting doesn't break at `r~0`. |
| `bench/bench_physics.gd` | **CHECK** | `_draw` cost ~same; verify `trail 8× <0.08ms` not regressed. |

**No changes to:** `TronPalette`, `PlanetPalette`, `DrawUtils` (still used by planets/asteroids/trails), `CameraController`, `game_controller.gd`, `orbital_body.gd`.

---

## 10. Implementation Phases

**Phase 0 — Scaffolding (0.5 day)**
- [ ] `ship_palette.gd` with tokens + doc comment
- [ ] Stub new `spaceship.gd` behind `if false` guard so `main` still launches with old ship while iterating (or branch-only).

**Phase 1 — Blockout Hull (1 day, this is the "wow" commit)**
- [ ] Replace `_hull_points` etc. with new facet arrays (nose, fwd hull, mid hull, spine, aft). Wire `_update_sun_lighting()` and flat-shade.
- [ ] Panel seams + rivets + dorsal truss (no wear yet). Greyscale only.
- [ ] Verify at `min_zoom` and `max_zoom` (`camera_controller.gd:4-5`), screenshot at dawn/dusk orbit.

**Phase 2 — Material + Sun Reflections (1 day)**
- [ ] Aluminum chamfer specular flashes, cockpit glass specular, dark engine block.
- [ ] Soot gradients on nozzles. Test with `sun_mass` sweep (progression `STAR_TYPES` 0.3–20 solar) — limb/mu math stays sane.

**Phase 3 — Grit Pass (0.75 day)**
- [ ] Paint chips, streaks, mismatched panel, bent antenna, port/starboard nav lights.
- [ ] Restyle plume → hot core/blue/outer. Add `RCS` puff on `ship_rotate_left/right` (`spaceship.gd:121-128` hook).

**Phase 4 — Indicator + Rocket (0.5 day)**
- [ ] New `_MarkerLayer` (amber dashed, 0.22 alpha) + nav blink logic. Update `progression.gd:271 _check_ship_click` hit radius (still 28*zoom, okay for new bounds — test).
- [ ] Rocket torpedo.

**Phase 5 — Polish & Perf (0.5 day)**
- [ ] Edge-case: `r < 1` guard already in `spaceship.gd:172`. Keep.
- [ ] Run `Godot --headless -s res://addons/gut/gut_cmdln.gd -gexit` + `bench/bench.gd` relaxation from `AGENTS.md`; commit `bench/baseline.json` if intentional.
- [ ] Optional: extract tiny glass shader if `_draw` streak looks too fake.

**Total ~4 days solo.** Phases 1+2 are the must-ship; 3+4 are the grit.

---

## 11. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Flat-shade looks faceted / "low poly" in a bad way | Chamfers are narrow (1.5–2px) so facets are subtle; restrict specular to chamfers only so hull still reads as one body. |
| New palette clashes with `BG = Color(0.039,0.039,0.102)` (`tron_palette.gd:11`) | Ship is light grey/white — intentional contrast against near-black BG, same as planets. Test against `sun_surface.gdshader` glare (ship shouldn't wash out when near sun — `HULL_PAINT_SHADOW` already darkens). |
| Hit-test (`progression.gd:274`) too small/large for new shape | Keep `COLLISION_RADIUS` 14; click radius `max(28*zoom,14)` already generous. Verify visually at `zoom=0.3`. |
| Loses TRON clickability hint | Nav blink + faint amber ring preserve affordance without neon. Playtest: if users miss it, raise ring alpha from 0.22 → 0.30 (still far below old 0.50 `RING_ALPHA_MAX`). |
| Strict typing (`project.godot:99-106` all `=2`) | New `ShipPalette` access via `const SHIP: GDScript = preload(...)` + `SHIPS.HULL_PAINT` etc., same pattern as `orbital_body.gd:14`. Suppress `unsafe_*` only where `Dictionary`/`Variant` is intentional. |

---

## 12. Visual References (for the implementer)

- **Primary:** Rocinante (The Expanse) — blocky, radiator fins, exposed plumbing.
- **Secondary:** Nostromo (Alien) — weathered industrial, yellow hazard stripes, patched plates.
- **Tertiary:** Sulaco (Aliens) + ISS Zvezda — utilitarian antennas, mismatched solar.
- **Anti-reference:** Any sleek white Starfleet shuttle — too clean, too aero.

Keep a `references/` folder (not committed) with 3 screenshots for the PR description.

---

## 13. Open Questions for Owner

1. **How far to push asymmetry?** Spec has one bent antenna + mismatched panel. Go further (e.g., one radiator fin shorter, as if clipped by debris) or keep symmetry for gameplay readability?
2. **Name / registry?** Hull lettering (e.g., "MULE-09" in stencil) adds story but tiny at 0.3× zoom — worth it or noise?
3. **Lighting model:** Flat-shade per-facet (proposed) vs true `ship_hull.gdshader` normal map. Former is 1 day, latter is 2–3 days + texture authoring. Preference?
4. **Rocket scope:** Restyle in same PR or follow-up issue?
5. **Selection ring:** Keep a ring at all (industrial amber) or kill it entirely and rely on nav lights + camera follow (`progression.gd:264 toggle_ship_follow`) as the only cue?

---

## 14. Acceptance Checklist

- [ ] Ship reads as physical object under sun at all orbit angles (chamfers flash, shadow side darkens).
- [ ] No `TronPalette`/`DrawUtils.neon_*` in `spaceship.gd` (except maybe rocket trail if kept).
- [ ] Collisions + `try_fire` + `enforce_sun_barrier` + pause behavior unchanged.
- [ ] Looks beaten up at 1× zoom, still legible at 0.3× zoom.
- [ ] `gdformat --check` + `gdlint` + `Godot --headless --editor --quit` clean (no `SCRIPT ERROR`).
- [ ] Manual QA screenshots: sun-side, terminator, night side, thrusting, selected/unselected.

