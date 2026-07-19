# Godot Space Idle — AGENTS.md

## Project overview

Single-scene Godot 4.7 (Forward Plus, 1920×1080) idle/clicker where you fly planets into a growing sun.

- Entry point: `scenes/main.tscn` (run/main_scene)
- All scripts in `scripts/` — GDScript only, no C# or GDExtension
- Sun clickable (left-click) to increase mass (+0.01/click); `+`/`-` or scroll to zoom; left/middle drag to pan
- `L` key spawns an asteroid manually

## Dev commands

There are no build/test/lint commands. This is a pure Godot project with no toolchain outside the editor.

- Open the project: `godot .` from repo root (or open `project.godot` in the Godot editor)
- No formatter, linter, typechecker, or test framework is configured
- No CI, no pre-commit hooks, no task runner
- Git operations use `rtk` wrapper: `rtk git status`, `rtk git diff`, `rtk git commit -m "..."`, `rtk git push`
- GitHub operations use `gh`: `gh issue create`, `gh pr create`

## Workflow

Every feature or fix follows this sequence:

Every feature or fix follows this sequence:

1. **GitHub Issue** — work starts from an existing issue (or create one first). Always add a label (`enhancement`, `bug`, etc.) when creating.
2. **Branch** — `rtk git checkout -b issue-N-description` off `main`
3. **Code** — implement the change
4. **Manual QA** — provide a list of specific test cases for the user to verify in the Godot editor
5. **PR** — once QA passes, commit, push, and `gh pr create` with `Closes #N` in the body
6. **Merge** — user merges via GitHub UI

**Important:** Before any `git commit` or `git push`, always verify the current branch with `git branch` or `git status` to avoid pushing to the wrong branch.

**Branch hygiene:** Keep branches rebased on `main` to avoid merge conflicts. Before creating a PR, run `rtk git rebase main` and resolve any conflicts locally.

## Scripts

| Script | Extends | Role |
|--------|---------|------|
| `main.gd` | `Node2D` | Root controller — owns all state, orchestrates planets, asteroids, star field, camera, UI, collisions |
| `orbital_body.gd` | `Node2D` | Base class for all planets — Newtonian orbital mechanics, trail recording, sun collision detection |
| `mercury.gd` | `orbital_body.gd` | Orbit radius 350, period 25s, mass 1.65e-7, grey |
| `venus.gd` | `orbital_body.gd` | Orbit radius 500, period 47s, mass 2.45e-6, golden |
| `earth.gd` | `orbital_body.gd` | Orbit radius 700, period 78s, mass 3.0e-6, blue-green |
| `mars.gd` | `orbital_body.gd` | Orbit radius 950, period 131s, mass 3.21e-7, reddish-brown |
| `jupiter.gd` | `orbital_body.gd` | Orbit radius 1400, period 355s, mass 9.54e-4, banded texture |
| `saturn.gd` | `orbital_body.gd` | Orbit radius 1800, period 616s, mass 2.86e-4, procedural ring (animated) |
| `uranus.gd` | `orbital_body.gd` | Orbit radius 2200, period 1074s, mass 4.35e-5, cyan-blue |
| `neptune.gd` | `orbital_body.gd` | Orbit radius 2600, period 1599s, mass 5.14e-5, deep blue |
| `asteroid.gd` | `Node2D` | Asteroids — spawn from outer field, affected by planet gravity, leave reddish trails, despawn >4000u |
| `texture_utils.gd` | — | Static `make_circle_texture(size, color_fn)` — procedural circle textures used by all planets |
| `tron_palette.gd` | `RefCounted` | `class_name TronPalette` — single source of truth for TRON design-language color and tuning tokens |
| `draw_utils.gd` | `RefCounted` | `class_name DrawUtils` — static neon drawing helpers (`neon_polyline`, `neon_arc`, `neon_segmented_ring`, `neon_circle`, `neon_filled_accent`, `pulsate_factor`, `modulate_alpha`) |
| `spaceship.gd` | `Node2D` | TRON-style vector wireframe mothership — cockpit diamond, swept wings, twin engine jets, segmented indicator ring (see PR #80) |

## Shaders

| Shader | Type | Role |
|--------|------|------|
| `shaders/star_blur.gdshader` | `canvas_item` | Per-layer blur for the parallax star field; `blur_amount` driven by camera zoom |
| `shaders/sun_noise.gdshader` | `canvas_item` | Runtime noise texture for the sun core; `time` parameter advanced each frame |
| `shaders/post_process.gdshader` | `canvas_item` | Screen-space chromatic aberration + scanline tint triggered by sun impacts |
| `shaders/menu_grid.gdshader` | `canvas_item` | TRON grid plane behind the main menu — repeating cyan lines over `BG`; tunables `line_color`, `cell_size`, `line_width` |

## Fonts

Three-font family in `resources/fonts/` (all SIL Open Font License). `game_theme.tres` declares all three as `ext_resource`s; `default_font` (inherited by `Button` and `Label`) stays Orbitron Medium so the generic look is unchanged. Two custom Label theme font slots expose the others so scripts can opt in via `preload("res://resources/fonts/…")`:

| Font file | Theme slot | Use | Applied by |
|-----------|------------|-----|------------|
| `Orbitron-Medium.ttf` | `default_font` (+ inherited `Label/fonts/font`, `Button/fonts/font`) | Headline / body labels, buttons, planet names, popup field labels, MassLabel fallback | `game_theme.tres` default — no per-control override needed |
| `Orbitron-Bold.ttf` | `Label/fonts/font_bold` | Big chunky titles only | `main_menu.gd` Title at 64pt via `add_theme_font_override` with `preload(...)` |
| `ShareTechMono-Regular.ttf` | `Label/fonts/font_mono` | Numerical HUD readouts (terminal/CMP feel) | `main.gd` & `progression.gd` MassLabel (18pt), `event_log.gd` log entries (11pt), `planet_popup.gd` value column (11pt) |

### Font conventions

1. **No new font files** without adding both (a) an `ext_resource` entry in `game_theme.tres` and (b) a row in the table above.
2. **Per-control overrides use `preload("res://resources/fonts/<file>.ttf")`**, not `load()` — preload is the codebase convention (see `tron_palette.gd` / `draw_utils.gd`).
3. **Numerical readouts use Share Tech Mono**; narrative labels (planet names, "Mass", "Speed" field labels in the popup) stay Orbitron Medium.
4. **Titles at 32pt and up use Orbitron Bold**; everything ≤20pt stays Orbitron Medium unless it's a mono readout.
5. **`.import` files** for the two new fonts are generated by the editor on first open (issue #94 acceptance criteria). Don't hand-edit them.

## Architecture

- **No autoloads/singletons** — `main.gd` owns all state and coordinates child nodes via `$` paths
- **Planets** inherit from `orbital_body.gd` which handles circular Newtonian orbits (`GM_UNIT` / `_initial_gm()`), trail recording (1200 points, Line2D rendering), and sun-collision detection. When a planet hits the sun it is marked dead (no respawn) and emits `collided_with_sun`. Each planet has a custom `_get_planet_color()` for its procedural texture. Saturn additionally generates a rotating ring sprite.
- **Body-body collisions** — `main.gd` checks planet-planet, planet-asteroid overlaps each frame. The larger body absorbs the smaller with momentum conservation; collision effects (impact rings + additive glow sprites) spawn at the merge point.
- **Asteroids** spawn every ~35–55s (max 3 alive), feel softened gravity from all planets, and despawn when >4000 units from origin.
- **Star field** — procedural parallax with canvas-item shaders (6 layers, edge-wrapping, seeded by `star_seed`). Blur amount driven by camera zoom via shader parameter.
- **Sun** — runtime-generated noise texture + shader (`sun_noise.gdshader`), 4 additive-blend glow sprites, pulsating `breathe` animation, collision flash on any impact.
- **Camera** — `Camera2D` with position smoothing and lerp-smoothed zoom (clamped 0.3–1.3×). Zoom level mapped to star-field blur.
- **Textures** — all generated in code (`Image.create` → `ImageTexture`); no imported assets beyond `icon.svg`
- **UI** — sun mass label, planet mass panel (`VBoxContainer` with per-planet mass/%/status), orbit trail lines (gradient-colored `Line2D`)

## Visual language

The game uses a single, shared TRON-inspired design language. All visual tokens live in `scripts/tron_palette.gd` (`class_name TronPalette`) and all neon-drawing recipes live in `scripts/draw_utils.gd` (`class_name DrawUtils`). **Never introduce new inline `Color` constants in component scripts** — pull from `TronPalette` so the look stays tunable from one place. Issues #81–#90 track the rollout.

### Palette (`TronPalette`)

| Token | Use |
|-------|-----|
| `BG` | Near-black navy background (clear color, panel fills) |
| `HULL_GLOW` / `HULL_LINE` / `HULL_BRIGHT` | Cyan 3-stroke triple-stack — primary wireframe color |
| `ACCENT` / `ACCENT_GLOW` | Orange — wing trims, asteroid strokes, sun crowns, engine highlights |
| `COCKPIT` / `COCKPIT_GLOW` | Bright cyan diamond + soft halo — focal bright accents |
| `ENGINE_PORT` / `PORT_CORE` / `FLAME_OUTER` / `FLAME_INNER` | Additive teal exhaust |
| `RING_GLOW` / `RING_LINE` / `RING_BRIGHT` | Segmented HUD-overlay rings (alpha already capped — see GUI-overlay rule) |
| `RING_ALPHA_MAX` (0.5), `RING_PULSE_MIN` (0.35), `RING_PULSE_SPEED` (2.5 rad/s) | Indicator-ring tuning |

### Stroke triple-stack — the TRON look

Every neon stroke is **three layered `draw_polyline` calls** — this recipe *is* the look:

| Layer | Width | Alpha | Role |
|-------|-------|-------|------|
| Glow  | 5.0 px | ~0.15-0.45 (token-dependent) | Wide soft underlayer → the bloom feel |
| Line  | 1.5 px | ~0.5-1.0 | Mid stroke — the visible edge |
| Bright | 0.5 px | ~0.5-1.0 | Crisp inner core — the " filament" highlight |

Call `DrawUtils.neon_polyline(canvas, points, glow, line, bright)` to apply all three in one call. Do not invent new widths — change `DrawUtils.NEON_*_WIDTH` constants if a global retune is needed. Similarly `neon_arc` / `neon_segmented_ring` / `neon_circle` apply the same triple-stack to curved geometry.

### Additive blending

All glow-bearing layers (spaceship thrust, indicator ring, impact fx, sun glow sprites) use `CanvasItemMaterial.BLEND_MODE_ADD` against the near-black `BG`. Additive math is what makes thin strokes "pop" without resorting to a heavy bloom pass. New glowy elements should follow the same pattern — instantiate a `CanvasItemMaterial`, set `blend_mode = BLEND_MODE_ADD`, assign to the node's `material`.

### GUI-overlay alpha cap (PR #80 rule)

Rings, reticles, HUD markers, and other overlay elements that should read as *GUI on top of the world* (not part of the ship/planet structure) **cap alpha at 50%**. The spaceship indicator ring (`TronPalette.RING_*` constants are already pre-capped at 0.15 / 0.475 / 0.50) is the reference implementation. Solid neon strokes (hull, sun crown, asteroid wireframe) are exempt — those use `HULL_*` / `ACCENT` at full alpha and read as physical structure.

### Pulsation convention

Any element that needs to "breathe" to hint at clickability (or other state) should swing alpha between `TronPalette.RING_PULSE_MIN` (0.35) and 1.0 of its capped base values at `TronPalette.RING_PULSE_SPEED` (2.5 rad/s ≈ 0.4 Hz). Use:

```gdscript
var alpha_mult := DrawUtils.pulsate_factor(phase, TronPalette.RING_PULSE_MIN)
var color := DrawUtils.modulate_alpha(TronPalette.RING_LINE, alpha_mult)
```

The caller advances `phase` itself (no hidden time dependence in the helper). The spaceship ring (`spaceship.gd:_RingLayer`) is the reference implementation — pulses only when not selected, holds steady when selected, phase keeps advancing so resumes are seamless.

### Reference helpers (`DrawUtils`)

| Function | Use for |
|----------|---------|
| `neon_polyline(canvas, points, glow, line, bright, antialias=true)` | 3-stroke neon on any polyline (hulls, braces, accents) |
| `neon_arc(canvas, center, r, a0, a1, segments, glow, line, bright, antialias=true)` | 3-stroke on a single arc segment |
| `neon_segmented_ring(canvas, center, r, segment_count, gap, glow, line, bright, antialias=true)` | Canonical TRON HUD-overlay ring (N arcs with symmetric gaps; first arc starts at `-PI/2 + gap/2` so the gap pattern is symmetric about the heading axis) |
| `neon_circle(canvas, center, r, glow, line, bright, segments=64, antialias=true)` | Closed 360° neon arc (planet rims, sun crowns) |
| `neon_filled_accent(canvas, points, fill, glow, line, antialias=true)` | Filled accent polygon (orange wing trims) — solid fill + 2 outer strokes |
| `pulsate_factor(phase, min_val=0.35) -> float` | Sine envelope in `[min_val, 1.0]` — for breathing animations |
| `modulate_alpha(c, factor) -> Color` | Scale a `Color`'s alpha while keeping RGB intact — for applying pulsate to base palette |

### Conventions for new components

1. **No inline `Color` literals** in component scripts — import `const PAL := preload("res://scripts/tron_palette.gd")` (and `DU := preload("res://scripts/draw_utils.gd")` for drawing) and reference `PAL.HULL_LINE` etc.
2. **Preload via `res://` path**, not via `class_name` global — GDScript rejects `const PAL := TronPalette` as a non-constant expression. The preload form is the codebase convention (see `progression.gd:37-42`, `orbital_body.gd:4-5`).
3. **Inner classes don't inherit preload aliases** — if a component uses inner classes (e.g. `spaceship.gd:_GlowLayer`), each inner class needs its own `const PAL := preload(...)` binding.
4. **No new shaders** when a `_draw()` + 3-stroke neon polyline achieves the look. Add a shader only when the effect genuinely needs per-pixel work (noise, blur, bloom — see issue #90).
5. **No new autoloads** — `TronPalette` and `DrawUtils` are pure `class_name` + preload, no singleton registration in `project.godot`.
6. **`resources/game_theme.tres` mirrors `TronPalette` literals** — `.tres` files cannot `preload()` a script, so the theme hardcodes the same RGB values as `TronPalette` (e.g. `Color(0.55, 0.95, 1.0, 0.5)` ≡ `TronPalette.HULL_LINE` at 50% alpha). When changing a token in `tron_palette.gd`, also update the corresponding literal in `game_theme.tres` and keep both rows of the table below in sync:

   | `TronPalette` token | `game_theme.tres` literal (RGB only) | Used as |
   |---------------------|-------------------------------------|---------|
   | `BG`                | `Color(0.04, 0.04, 0.102, …)`       | Panel + button bg |
   | `HULL_LINE`         | `Color(0.55, 0.95, 1.0, …)`         | Button + panel border (alpha 0.5 = GUI-cap) |
   | `HULL_BRIGHT`       | `Color(0.92, 1.0, 1.0, …)`         | Button + Label `font_color`, hover/pressed border |
   | `HULL_GLOW`         | `Color(0.18, 0.55, 1.0, 0.45)`     | `font_outline_color` (Button + Label) |

   The exported theme applies to: `Button`, `Label`, `Panel`. The MassLabel in `main.tscn` / `progression.tscn` uses no inline `theme_override_*` — it picks up `Label/font_sizes/font_size = 18` from the theme (a deliberate headline weight; other Labels all override to 11 in-script and are unaffected). Per-control font overrides follow the dual-font family convention described in the **Fonts** section above: titles opt into `Orbitron-Bold.ttf` via `add_theme_font_override("font", preload(...))`, and HUD readouts opt into `ShareTechMono-Regular.ttf` the same way. The MassLabel is given the mono face in-script by `main.gd` / `progression.gd` so it remains Size 18 from the theme but switches to terminal type.
