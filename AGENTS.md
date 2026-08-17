# Godot Space Idle — AGENTS.md

## Project overview

Single-scene Godot 4.7 (Forward Plus, 1920×1080) gravity sandbox with idle/clicker elements — planets orbit under Newtonian mechanics, asteroids drift through the system, and bodies can collide and merge.

- Entry point: `scenes/main_menu.tscn` (run/main_scene) — the main menu is the launch screen; `scenes/main.tscn` is the sandbox scene and `scenes/progression.tscn` is the progression scene, both reached from the menu
- All scripts in `scripts/` — GDScript only, no C# or GDExtension
- Sun clickable (left-click) to increase mass (+0.1/click); `+`/`-` or scroll to zoom; left/middle drag to pan
- `L` key spawns an asteroid manually; `Esc` toggles pause menu

## Dev commands

- Open the project: `godot .` from repo root (or open `project.godot` in the Godot editor)
- **Godot Steam path:** The editor and headless binary are at `/Users/avantgardian/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot` — use this for headless CI/test commands instead of bare `godot`
- **Run tests (headless CI):** `godot --headless -s res://addons/gut/gut_cmdln.gd -gexit -gmaximize` (auto-loads config from `.gutconfig.json`)
- **Run tests (editor):** Open the GUT panel via the editor dock (enabled by `addons/gut/plugin.cfg`) and click "Run All", or load `res://tests/test_runner.tscn` and run the scene
- **Format/lint:** `gdformat --check scripts/` and `gdlint scripts/` (install via `pip install gdtoolkit==4.5.0`)
- **Pre-commit:** `pre-commit run --all-files` (install via `pre-commit install`; see `.pre-commit-config.yaml`) — gdtoolkit is pinned to **4.5.0** in both pre-commit hooks and CI
- **CI:** `.github/workflows/ci.yml` runs `lint` (gdformat --check + gdlint) and `test` (GUT) jobs on push/PR to non-main branches; `.github/workflows/check.yml` checks script compilation
- **Dependabot:** `.github/dependabot.yml` auto-bumps GitHub Actions and gdtoolkit on a monthly schedule
- Git operations use `rtk` wrapper: `rtk git status`, `rtk git diff`, `rtk git commit -m "..."`, `rtk git push`
- GitHub operations use `gh`: `gh issue create`, `gh pr create`

## GDScript conventions

- **Class definition order is fixed** — gdlint `class-definitions-order` (enforced by CI and pre-commit) rejects any other arrangement. Write members in exactly this order:
  1. `tool`
  2. `extends`
  3. `class_name`
  4. `enum`
  5. `const`
  6. `signal`
  7. `var` (member variables)
  8. `onready`
  9. `func` / methods

  **Forward references are allowed:** a `signal` may name a type defined by an `enum`/`const` below it, and vice versa — but the declaration order above still applies regardless of dependencies. (e.g. `signal resolved(reason: Resolution)` is valid even though `enum Resolution` must appear before it.)
- **Lambda capture is by value** — a lambda connected to a signal captures local variables at connect time; `count += 1` inside the lambda does not mutate the outer local. Use a shared container (`var got: Array = []` + `got.append(...)`) or a method instead when the callback must write back.
- **No inline `Color` literals** in component scripts — TRON-scoped elements pull from `TronPalette`, realism-scoped body surfaces pull from `PlanetPalette` (see Visual language section).

## Workflow

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
| `controllers/game_controller.gd` | `Node2D` | Base controller for both game modes — owns all shared state (sun mass, settings, pause), orchestrates asteroids, star field, camera, UI. Handles `Esc` pause toggle and pause menu lifecycle. |
| `controllers/main.gd` | `game_controller.gd` | Sandbox mode — adds 8 planets, planet popup, collision manager wiring |
| `controllers/progression.gd` | `game_controller.gd` | Progression mode — adds star type generation, spaceship, ship controls, rocket targeting |
| `controllers/collision_manager.gd` | `RefCounted` | `class_name CollisionManager` — manages all body-body collisions (planet-planet, planet-asteroid, planet-rocket) with mass-based absorption, momentum conservation, and impact effect spawning |
| `bodies/orbital_body.gd` | `Node2D` | `class_name OrbitalBody` — base class for all planets. Newtonian orbital mechanics via full integration (`a = -GM/r²`), trail recording, sun collision detection. All 8 planets (Mercury through Neptune) are `OrbitalBody` nodes in `main.tscn` configured via `@export` variables (`orbit_radius`, `orbit_period`, `mass`, `biome`, `collision_profile`, `planet_seed`) — no individual planet scripts exist. Single `@export var biome: BiomeConfig` delegates surface rendering to a `BiomeConfig` Resource (see `scripts/biomes/`). Common shader uniforms (`u_time`, `u_light_dir`, `u_ambient`, `u_night_rim`, `u_axial_tilt`, `u_spin_rate`, `u_seed`) are set here; biome-specific uniforms are applied by `BiomeConfig.apply_to_shader()`. Atmosphere rim is handled cross-biome via `atm_color`/`atm_thickness_mult`/`atm_intensity`/`atm_ambient` exports. |
| `bodies/asteroid.gd` | `Node2D` | Asteroids — spawn from outer field, affected by planet gravity, leave orange trails (TRON accent), despawn >5000u. Biome-driven surface shader via `@export var biome`. |
| `bodies/sun.gd` | `Sprite2D` | Central sun — procedural surface shader with fbm granulation and Eddington-Milne limb darkening, additive glow sprites (corona), pulsating breathe animation, collision flash on impact. Spot machinery is force-disabled (`sun.gd:69-70`). |
| `components/spaceship.gd` | `Node2D` | TRON-style vector wireframe mothership — cockpit diamond, swept wings, twin engine jets, segmented indicator ring (see PR #80) |
| `components/ring_system.gd` | `Node2D` | `class_name RingSystemComponent` (see issue #199) — builds back/front ring sprites with ring shader materials, updates light direction in `_physics_process`. `@export` params for ring geometry, colors, and seed. Attached as a child of any `OrbitalBody` (currently Saturn). |
| `components/camera_controller.gd` | `Camera2D` | `class_name CameraController` — smooth zoom/pan via mouse wheel and left/middle drag, screen shake, optional follow-target tracking |
| `components/asteroid_spawner.gd` | `Node` | `class_name AsteroidSpawner` — spawns asteroids at intervals from the outer field, passing planet data for gravity and sun-hit callbacks |
| `components/star_field.gd` | `Node2D` | Six-layer procedural parallax star-field — each layer of `Sprite2D`s uses a blur shader driven by camera zoom. Seeded by `star_seed`. |
| `components/trail_component.gd` | `Node2D` | `class_name TrailComponent` — draws gradient-colored trailing `Line2D` ribbons behind moving bodies (planets, asteroids, rockets) using a ring buffer with graceful downsampling |
| `components/post_process_manager.gd` | `Node` | `class_name PostProcessManager` — full-screen post-processing: chromatic aberration impact flash, color-blindness correction (via `cb_correct.gdshader`), bloom intensity |
| `components/impact_fx.gd` | `Node2D` | Spawns TRON-style impact rings and additive glow sprites at collision merge points |
| `components/rocket.gd` | `Node2D` | `class_name Rocket` — TRON-style homing rocket projectile; seeks targets, draws a neon trail, dies on collision or lifetime expiry. Spawned by the spaceship in progression mode. |
| `ui/pause_button.gd` | `Button` | Bottom-right Pause/Play button — emits `pause_toggled` signal; controller owns pause state |
| `ui/pause_menu.gd` | `Panel` | Full-screen TRON pause overlay — Resume (unpause), Save/Load (disabled placeholders), Exit to Main Menu; handles `Esc` to unpause via `_input()` (has `PROCESS_MODE_ALWAYS`) |
| `ui/planet_popup.gd` | `Panel` | `class_name PlanetPopup` — TRON-styled planet info tooltip; follows a planet on-screen showing mass, orbit stats, and biome details |
| `ui/sun_popup.gd` | `Panel` | `class_name SunPopup` — TRON-styled sun info tooltip; follows the sun on-screen displaying mass and star type label |
| `ui/event_log.gd` | `Node` | `class_name EventLog` — scrollable event-log panel; displays timed collision/absorption messages in monospace with auto-fade after 60s |
| `ui/main_menu.gd` | `Control` | Main menu screen — title, Sandbox/Progression/Settings/Quit buttons with TRON theming |
| `ui/settings.gd` | `Control` | `class_name SettingsScreen` — settings screen: reduced motion, screen shake, colorblind mode toggles, and key rebinding |
| `biomes/biome_config.gd` | `Resource` | Abstract `BiomeConfig` base — `get_shader()`, `get_texture_size()`, `apply_to_shader(mat)`, `seed_features(seed_val)`, `sync_features(mat)` |
| `biomes/rocky_biome.gd` | `BiomeConfig` | Rocky surface shader + crater seeding (Mercury, Mars) |
| `biomes/greenhouse_biome.gd` | `BiomeConfig` | Thick-cloud greenhouse shader (Venus) |
| `biomes/terrestrial_biome.gd` | `BiomeConfig` | Earth-like land/ocean/cloud shader |
| `biomes/gas_giant_biome.gd` | `BiomeConfig` | Banded gas giant shader + random storm seeding (Saturn) |
| `biomes/jupiter_biome.gd` | `GasGiantBiomeConfig` | Gas giant with fixed Great Red Spot storm seeding |
| `biomes/ice_giant_biome.gd` | `BiomeConfig` | Methane-blue ice giant shader + random storm seeding (Uranus) |
| `biomes/neptune_biome.gd` | `IceGiantBiomeConfig` | Ice giant with fixed Great Dark Spot storm seeding |
| `util/texture_utils.gd` | — | Static `make_circle_texture(size, color_fn)` — procedural circle textures used by all planets |
| `util/tron_palette.gd` | `RefCounted` | `class_name TronPalette` — single source of truth for TRON design-language color and tuning tokens (GUI chrome, trails, HUD overlays) |
| `util/planet_palette.gd` | `RefCounted` | `class_name PlanetPalette` — single source of truth for realism-side planet biome photometric color tokens (rocky, greenhouse, terrestrial, gas giant, ice giant, atmospheres, rings). Sibling to `TronPalette` — see Visual language section for the split. |
| `util/draw_utils.gd` | `RefCounted` | `class_name DrawUtils` — static neon drawing helpers (`neon_polyline`, `neon_arc`, `neon_segmented_ring`, `neon_circle`, `neon_filled_accent`, `pulsate_factor`, `modulate_alpha`) |
| `util/settings_manager.gd` | `RefCounted` | `class_name SettingsManager` — persists user settings (reduced motion, screen shake, keybinds, colorblind mode) to `user://settings.cfg` |
| `util/collision_profile.gd` | `Resource` | `class_name CollisionProfile` — exported resource defining visual parameters for a collision impact ring (flash, color, width, segments, duration) |
| `util/test_runner_scene.gd` | `Node2D` | GUT test runner scene — instantiates `GutRunner`, loads `.gutconfig.json`, and auto-runs all tests on `_ready()` |

## Shaders

| Shader | Type | Role |
|--------|------|------|
| `shaders/world/star_blur.gdshader` | `canvas_item` | Per-layer blur for the parallax star field; `blur_amount` driven by camera zoom |
| `shaders/world/sun_surface.gdshader` | `canvas_item` | Stellar surface shader: fbm/ridged/granulation noise in spherical lat/lon space, Eddington-Milne limb darkening, 3-stop core color ramp, flicker |
| `shaders/world/post_process.gdshader` | `canvas_item` | Screen-space chromatic aberration + scanline tint triggered by sun impacts |
| `shaders/world/menu_grid.gdshader` | `canvas_item` | TRON grid plane behind the main menu — repeating cyan lines over `BG`; tunables `line_color`, `cell_size`, `line_width` |
| `shaders/world/cb_correct.gdshader` | `canvas_item` | Color-blindness correction shader — managed by `PostProcessManager` for deuteranopia/protanopia/tritanopia simulation |
| `shaders/bodies/planet_rocky.gdshader` | `canvas_item` | Rocky surface shader (Mercury, Mars) — cratered terrain with axial tilt, spin, Lambert diffuse |
| `shaders/bodies/planet_greenhouse.gdshader` | `canvas_item` | Thick-cloud greenhouse shader (Venus) — dense atmosphere with cloud banding |
| `shaders/bodies/planet_terrestrial.gdshader` | `canvas_item` | Earth-like land/ocean/cloud shader with biome-driven landmass distribution |
| `shaders/bodies/planet_gas_giant.gdshader` | `canvas_item` | Banded gas giant shader (Jupiter, Saturn) — latitudinal bands, storm spots |
| `shaders/bodies/planet_ice_giant.gdshader` | `canvas_item` | Methane-blue ice giant shader (Uranus, Neptune) — hazy atmosphere with storm features |
| `shaders/bodies/atmosphere_rim.gdshader` | `canvas_item` (+ `blend_add`) | Atmosphere rim glow sibling sprite (#110): additive limb sprite whose alpha is driven by `dot(pixel_dir, u_light_dir)`, peaks at the disk edge via a Gaussian annulus, fades outward exponentially. Gated per-planet by `atm_color.a > 0`. |
| `shaders/bodies/asteroid_surface.gdshader` | `canvas_item` | Asteroid surface shader — cratered rocky surface with taxonomic archetype colors (C/S/M/X, #175) |
| `shaders/bodies/ring_system.gdshader` | `canvas_item` | Procedural ring system shader (Saturn) — Cassini/Encke divisions, light-direction driven illumination |

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

- **No autoloads/singletons** — `game_controller.gd` owns all shared state (sun mass, pause, settings) and coordinates child nodes via `%` unique-name access. `main.gd` and `progression.gd` extend it for sandbox and progression modes respectively.
- **Pause** — `Esc` or the bottom-right PauseButton toggles `get_tree().paused`. A full-screen `PauseMenu` overlay appears with Resume, Save/Load (disabled placeholders), and Exit to Main Menu buttons. `PROCESS_MODE_ALWAYS` nodes (Camera2D, PauseButton, PauseMenu) continue to process input while paused; the rest of the tree freezes.
- **Planets** inherit from `orbital_body.gd` which handles circular Newtonian orbits (`GM_UNIT` / `_initial_gm()`), trail recording (1200 points, Line2D rendering), and sun-collision detection. When a planet hits the sun it is marked dead (no respawn) and emits `collided_with_sun`. All 8 planets (Mercury through Neptune) are `OrbitalBody` nodes in `main.tscn` configured via `@export` variables (`orbit_radius`, `orbit_period`, `mass`, `biome`, `collision_profile`, `planet_seed`) — no individual planet scripts exist. Single `@export var biome: BiomeConfig` delegates surface rendering to a `BiomeConfig` Resource (see `scripts/biomes/`). Saturn additionally has a `RingSystemComponent` child for procedural rings.
- **Body-body collisions** — `CollisionManager` checks planet-planet, planet-asteroid, and planet-rocket overlaps each frame. The larger body absorbs the smaller with momentum conservation; collision effects (impact rings + additive glow sprites) spawn at the merge point.
- **Asteroids** spawn every ~35–55s, feel softened gravity from all planets, and despawn when >5000 units from origin.
- **Star field** — procedural parallax with canvas-item shaders (6 layers, edge-wrapping, seeded by `star_seed`). Blur amount driven by camera zoom via shader parameter.
- **Sun** — runtime-generated white-disk mask texture + realism shader (`sun_surface.gdshader`), sibling additive-blend glow sprites (corona), pulsating `breathe` animation, collision flash on any impact. Spot machinery exists in `sun.gd` but is force-disabled per user feedback (`sun.gd:69-70`).
- **Camera** — `Camera2D` with position smoothing and lerp-smoothed zoom (clamped 0.3–4.0×). Zoom level mapped to star-field blur.
- **Textures** — all generated in code (`Image.create` → `ImageTexture`); no imported assets beyond `icon.svg`
- **UI** — sun mass label, planet mass panel (`VBoxContainer` with per-planet mass/%/status), orbit trail lines (gradient-colored `Line2D`)

## Visual language

The project uses **two distinct visual languages** that should not be mixed:

1. **TRON neon** — GUI chrome only: menus, buttons, panels, the spaceship, HUD overlay rings (e.g. the spaceship indicator ring, selection reticles), mouse-over highlights, and the **trail lines** asteroids/planets leave behind. All TRON visual tokens live in `scripts/util/tron_palette.gd` (`class_name TronPalette`) and all neon-drawing recipes live in `scripts/util/draw_utils.gd` (`class_name DrawUtils`). **Never introduce new inline `Color` constants in TRON-scoped component scripts** — pull from `TronPalette` so the look stays tunable from one place. Issues #81–#90 track the rollout.

2. **Realism** — the celestial bodies themselves: the sun's surface, planet surfaces/atmospheres, and asteroid bodies. These render with physically-motivated shading (Lambert diffuse, limb darkening, atmospheric scattering, fbm noise) and photometric colors. Do **not** force-fit celestial body colors into the TRON cyan/orange palette. Realism colors live in `scripts/util/planet_palette.gd` (`class_name PlanetPalette`, sibling to `TronPalette`) for planets/moons/rings/atmospheres, or inline in `shaders/world/sun_surface.gdshader` uniforms for the sun. The TRON rules (triple-stack neon, GUI-alpha cap, additive bloom glows) do **not** apply to body surfaces; they only apply to TRON-scoped elements (so a planet may have a realistic Earth-blue surface + a TRON-cyan mouse-over ring stacked on top — both languages coexisting on one node).

The sun is the reference implementation of the split: its surface is a realism shader (`shaders/world/sun_surface.gdshader`), while its corona crown and impact rings are TRON neon overlays.

### Scope table — which language applies where

| Element | Language | Tokens live in |
|---------|----------|----------------|
| Menus, buttons, panels, MassLabel, EventLog | TRON | `TronPalette` + `game_theme.tres` |
| Spaceship (hull, cockpit, ring, engines) | TRON | `TronPalette` |
| HUD overlay rings (selection, mouse-over, reticles) | TRON | `TronPalette` (`RING_*`) |
| Trail Line2Ds (planet/asteroid trails) | TRON | `TronPalette` + `DrawUtils.trail_head/tail` |
| Sun surface (granulation, spots, limb darkening) | Realism | `sun_surface.gdshader` uniforms |
| Sun corona crown + impact ring | TRON overlay | `TronPalette` |
| Planet surfaces (rocky, greenhouse, terrestrial, gas, ice) | Realism | Per-biome shaders (`shaders/bodies/planet_*.gdshader`) + `PlanetPalette` |
| Planet atmospheres / rim glow | Realism | shader uniforms |
| Planet rings (Saturn-style) | Realism | shader uniforms |
| Asteroid bodies | Realism | `asteroid_surface.gdshader` + `PlanetPalette` |
| Asteroid trails | TRON | `TronPalette` + `DrawUtils.trail_head/tail` |

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

### Palette (`PlanetPalette`)

Sibling to `TronPalette`, single source of truth for realism-side biome photometric colors (`class_name PlanetPalette`, `scripts/util/planet_palette.gd`). Token groups:

| Token group | Use |
|-------------|-----|
| `ROCKY_MERCURY_HI/LO`, `ROCKY_MARS_HI/LO`, `ROCKY_MARS_ICE`, `ROCKY_CRATER_SHADOW` | Rocky biomes (Mercury, Mars, dead moons) |
| `ROCKY_ASTEROID_C_HI/LO`, `ROCKY_ASTEROID_S_HI/LO`, `ROCKY_ASTEROID_M_HI/LO`, `ROCKY_ASTEROID_X_HI/LO` | Asteroid taxonomic archetypes (C/S/M/X, #175) |
| `VENUS_CLOUD_HI/LO`, `VENUS_SURFACE_LAVA` | Greenhouse / hot thick cloud decks (Venus) |
| `TERRA_OCEAN_DEEP/SHALLOW`, `TERRA_LAND_TROPICAL/DESERT/TUNDRA`, `TERRA_ICE_CAP`, `TERRA_CLOUD_WHITE`, `TERRA_OCEAN_SPECULAR` | Terrestrial / habitable worlds (Earth) |
| `GAS_BAND_TAN_HI/LO`, `GAS_STORM_RUST`, `GAS_STORM_WHITE`, `SATURN_BAND_HI/LO` | Gas giants (Jupiter base + Saturn) |
| `ICE_METHANE_BLUE`, `ICE_DEEP_BLUE`, `ICE_STORM_DARK`, `ICE_HAZE_WHITE` | Ice giants (Uranus, Neptune) |
| `ATM_RIM_EARTH/VENUS/MARS/ICE` | Atmospheric rim glow (sibling additive limb sprite, #110) |
| `RING_SATURN_TAN`, `RING_SATURN_DARK` | Saturn-style ring system (#108) |

**Convention**: planet shaders and biome issues (#104–#109) consume these via `const PAL := preload("res://scripts/util/planet_palette.gd")` and feed the resulting RGB into shader uniforms as `Vector3(color.r, color.g, color.b)`. Do **not** inline `Color(...)` literals in biome-specific shader / script code — add new biome tokens to `PlanetPalette` instead. Unlike `TronPalette`, `PlanetPalette` does **not** need a `game_theme.tres` mirror (no Button/Label/Panel consumes biome colors — only shader uniforms).

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

1. **No inline `Color` literals** in component scripts — for TRON-scoped elements import `const PAL := preload("res://scripts/util/tron_palette.gd")` and reference `PAL.HULL_LINE` etc. For realism-scoped celestial body surfaces import `const PAL := preload("res://scripts/util/planet_palette.gd")` and reference `PAL.TERRA_OCEAN_DEEP` etc. (See Visual language section for the TRON vs Realism split.) Add `DU := preload("res://scripts/util/draw_utils.gd")` only when the component actually draws neon.
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
