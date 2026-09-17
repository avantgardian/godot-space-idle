# Godot Space Idle

A gravity sandbox built in Godot 4.7 with idle/clicker elements. Planets orbit under Newtonian mechanics, asteroids drift through the system, and bodies can collide and merge.

## Running

Open the project in the Godot editor:

```sh
godot .
```

Or open `project.godot` from the Godot Project Manager.

## Testing

```sh
godot --headless -s res://addons/gut/gut_cmdln.gd -gexit -gmaximize
```

Or open the GUT panel from the editor dock and click "Run All".

Headless gameplay smoke (catches runtime `push_error` / `SCRIPT ERROR` without the editor):

```sh
godot --headless -s res://bench/gameplay_smoke.gd
# or filtered: godot --headless -s res://bench/gameplay_smoke.gd -- --scene main --frames 600 --seed 42
```

Full CI parity without the editor (lint + typing + GUT + qa-smoke + perf):

```sh
bash scripts/qa.sh
# single gate: bash scripts/qa.sh --qa-smoke-only
```

## Contributing

Development workflow and conventions are documented in [AGENTS.md](AGENTS.md). See [CONTRIBUTING.md](CONTRIBUTING.md) for the contributor workflow summary.

## License

This project is licensed under the [MIT License](LICENSE).
