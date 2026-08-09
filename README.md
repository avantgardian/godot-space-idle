# Godot Space Idle

A gravity sandbox built in Godot 4.7 with idle/clicker elements. Planets orbit under Newtonian mechanics, asteroids drift through the system, and bodies can collide and merge.

![screenshot](screenshot.png)

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

## Contributing

Development workflow and conventions are documented in [AGENTS.md](AGENTS.md). See [CONTRIBUTING.md](CONTRIBUTING.md) for the contributor workflow summary.

## License

This project is licensed under the [MIT License](LICENSE).
