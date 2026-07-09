# Godot Space Idle — AGENTS.md

## Project overview

Single-scene Godot 4.7 (Forward Plus, 1920×1080) idle/clicker where you fly planets into a growing sun.

- Entry point: `scenes/main.tscn` (run/main_scene)
- All scripts in `scripts/` — GDScript only, no C# or GDExtension
- Sun clickable (left-click) to increase mass; `+`/`-` or scroll to zoom; drag to pan

## Dev commands

There are no build/test/lint commands. This is a pure Godot project with no toolchain outside the editor.

- Open the project: `godot .` from repo root (or open `project.godot` in the Godot editor)
- No formatter, linter, typechecker, or test framework is configured
- No CI, no pre-commit hooks, no task runner

## Architecture notes

- No autoloads/singletons; `main.gd` owns all state and coordinates child nodes via `$` paths
- Planets (`mercury.gd`, `venus.gd`) use Newtonian orbital mechanics (`GM_UNIT` / `_initial_gm()`), orbit the Sun, respawn 2s after collision
- Asteroids (`asteroid.gd`) spawn from the outer field every ~35–55s, max 3 alive at once
- Star field uses procedural parallax with canvas-item shaders (6 layers, seeded by `star_seed`)
- Sun shader + glows generated at runtime (additive blend sprites)
- Camera is a `Camera2D` smoothed child of the root; zoom applies star blur via shader parameter
- All textures generated in code (`Image.create` → `ImageTexture`); no imported assets beyond `icon.svg`
