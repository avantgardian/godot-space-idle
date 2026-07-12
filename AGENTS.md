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

1. **GitHub Issue** — work starts from an existing issue (or create one first)
2. **Branch** — `rtk git checkout -b issue-N-description` off `main`
3. **Code** — implement the change
4. **Manual QA** — provide a list of specific test cases for the user to verify in the Godot editor
5. **PR** — once QA passes, commit, push, and `gh pr create` with `Closes #N` in the body
6. **Merge** — user merges via GitHub UI

**Important:** Before any `git commit` or `git push`, always verify the current branch with `git branch` or `git status` to avoid pushing to the wrong branch.

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
