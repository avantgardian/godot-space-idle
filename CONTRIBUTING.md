# Contributing

Workflow guidance and code conventions live in [AGENTS.md](AGENTS.md). Read it before opening a PR.

## Quick reference

1. Start from a [GitHub issue](https://github.com/avantgardian/godot-space-idle/issues).
2. Branch off `main`: `git checkout -b issue-N-description`
3. Implement, test, and follow the conventions in [AGENTS.md](AGENTS.md).
4. Open a pull request with `Closes #N` in the description.

All PRs run lint (`gdformat --check`, `gdlint`), strict-typing (`Godot --headless --editor --quit` with `debug/gdscript/warnings/* = 2` — fails on `SCRIPT ERROR`), and GUT tests in CI.

## Strict typing

New code must satisfy `project.godot:99-106` `debug/gdscript/warnings/* = 2` (error):

- Every `func` has an explicit return type: `func foo() -> void:` or `-> Type`. Lambdas too: `func(x: Type) -> void:`.
- Every `var` is typed: `var x: Type`, `var x: Type = val`, or inferred `var x := typed_val` where the right-hand side is already typed. No bare `var x = val` (Variant).
- Signal declarations, `@export` vars, and `const` use explicit types. Prefer typed arrays (`Array[Node2D]`) where element type is known.
- `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument`, `inferred_declaration`, and `untyped_declaration` are errors. When Variant is intentional (e.g., `%UniqueName` node lookups, `Dictionary` planet/star data, `InputEvent` variant dispatch, `ConfigFile.get_value()` returning `Variant`), suppress **only that line** with `@warning_ignore("unsafe_*", ...)` (immediately preceding the line) and add `as Type` casts where needed. Do not disable warnings globally.
- New file with `func foo():` (missing `-> void`) fails CI/editor as error.

Local parity: `pre-commit run --all-files` includes the `godot-typing` hook (mirrors CI; set `GODOT_BIN` to override the default Steam path). CI and local dev agree — no Godot vs Rider drift.
