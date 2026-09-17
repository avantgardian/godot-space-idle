# Contributing

Workflow guidance and code conventions live in [AGENTS.md](AGENTS.md). Read it before opening a PR.

## Quick reference

1. Start from a [GitHub issue](https://github.com/avantgardian/godot-space-idle/issues).
2. Branch off `main`: `git checkout -b issue-N-description`
3. Implement, test, and follow the conventions in [AGENTS.md](AGENTS.md).
4. Open a pull request with `Closes #N` in the description.

All PRs run lint (`gdformat --check`, `gdlint`), strict-typing (`Godot --headless --editor --quit` with `debug/gdscript/warnings/* = 2` — fails on `SCRIPT ERROR`), and GUT tests in CI. Each PR also gets a playable preview at `https://avantgardian.github.io/godot-space-idle/pr-preview/pr-<N>/` (comment+QR, auto-removed on merge/close); `main` deploys to `https://avantgardian.github.io/godot-space-idle/`.

## Strict typing

New code must satisfy `project.godot:98-147` `debug/gdscript/warnings/* = 2` (49/50 error, `return_value_discarded=0` deferred — see `AGENTS.md` audit):

- Every `func` has an explicit return type: `func foo() -> void:` or `-> Type`. Lambdas too: `func(x: Type) -> void:`.
- Every `var` is typed: `var x: Type`, `var x: Type = val`, or inferred `var x := typed_val` where the right-hand side is already typed. No bare `var x = val` (Variant).
- Signal declarations, `@export` vars, and `const` use explicit types. Prefer typed arrays (`Array[Node2D]`) where element type is known.
- `untyped_declaration`, `inferred_declaration`, `unsafe_*`, and 43 other warnings are `2` (error); `return_value_discarded` is `0` (deferred — 47 fixes, spammy per Godot docs). When Variant is intentional (e.g., `%UniqueName` node lookups, `Dictionary` planet/star data, `InputEvent` variant dispatch, `ConfigFile.get_value()` returning `Variant`), suppress **only that line** with `@warning_ignore("unsafe_*", ...)` (immediately preceding the line) and add `as Type` casts where needed. Do not disable warnings globally.
- New file with `func foo():` (missing `-> void`) fails CI/editor as error.

Local parity: `pre-commit run --all-files` includes the `godot-typing` hook (mirrors CI; set `GODOT_BIN` to override the default Steam path). CI and local dev agree — no Godot vs Rider drift.
