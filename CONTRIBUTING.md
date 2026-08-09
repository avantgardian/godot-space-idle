# Contributing

Workflow guidance and code conventions live in [AGENTS.md](AGENTS.md). Read it before opening a PR.

## Quick reference

1. Start from a [GitHub issue](https://github.com/avantgardian/godot-space-idle/issues).
2. Branch off `main`: `git checkout -b issue-N-description`
3. Implement, test, and follow the conventions in [AGENTS.md](AGENTS.md).
4. Open a pull request with `Closes #N` in the description.

All PRs run lint (`gdformat --check`, `gdlint`) and GUT tests in CI.
