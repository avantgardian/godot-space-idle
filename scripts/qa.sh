#!/usr/bin/env bash
# Headless QA wrapper — single-command parity with CI (issue #336).
# Runs lint + typing + test + qa-smoke + perf headlessly, no editor required.
# Usage: bash scripts/qa.sh [--lint-only|--typing-only|--test-only|--qa-smoke-only|--qa-visual-only|--perf-only]
#   GODOT_BIN override: export GODOT_BIN=/path/to/Godot (default: Steam + PATH fallback)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT_BIN="${GODOT_BIN:-/Users/avantgardian/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$GODOT_BIN" ] && command -v godot >/dev/null 2>&1; then
	GODOT_BIN="$(command -v godot)"
fi
HAS_GODOT=0
if [ -x "$GODOT_BIN" ]; then HAS_GODOT=1; fi

ERR_PAT="SCRIPT ERROR|SHADER ERROR|Shader compilation failed|ERROR.*(Failed|Resource file not found|Parse [Ee]rror|Could not preload|Cannot open file)"
ERR_PAT_QA="SCRIPT ERROR|SHADER ERROR|Shader compilation failed|push_error|push_warning|WARNING|Invalid get index|Condition.*failed|ERROR.*(Failed|Resource file not found|Parse [Ee]rror|Could not preload|Cannot open file)"

STEP_FILTER="${1:-}"

run_lint() {
	echo "=== qa: lint (gdformat + gdlint) ==="
	gdformat --check scripts/ tests/ bench/
	gdlint scripts/ tests/ bench/
	echo "lint passed"
}

run_typing() {
	echo "=== qa: typing (strict warnings=2) ==="
	if [ "$HAS_GODOT" -eq 0 ]; then
		echo "::warning::Godot binary not found (tried \$GODOT_BIN=$GODOT_BIN and godot on PATH) - skipping typing"
		echo "hint: export GODOT_BIN=/path/to/Godot or brew install godot"
		if [ "${CI:-}" = "true" ]; then echo "::error::missing Godot binary in CI"; return 1; fi
		return 0
	fi
	set -o pipefail
	echo "--- editor --quit ---"
	"$GODOT_BIN" --headless --editor --quit 2>&1 | tee /tmp/godot_typing.log; EC=${PIPESTATUS[0]}
	if [ "$EC" -ne 0 ]; then echo "Godot --editor --quit exited $EC"; cat /tmp/godot_typing.log; return "$EC"; fi
	if grep -qE "$ERR_PAT" /tmp/godot_typing.log; then echo "Strict typing / shader errors"; grep -E "$ERR_PAT" /tmp/godot_typing.log; cat /tmp/godot_typing.log; return 1; fi
	echo "--- per-file check ---"
	while IFS= read -r -d '' f; do
		"$GODOT_BIN" --headless --check-only --script "res://$f" >> /tmp/godot_typing.log 2>&1; EC=$?
		if [ "$EC" -ne 0 ]; then echo "check-only $f exited $EC"; fi
	done < <(find scripts -name "*.gd" -print0)
	if grep -qE "$ERR_PAT" /tmp/godot_typing.log; then echo "Resource errors (per-file)"; grep -E "$ERR_PAT" /tmp/godot_typing.log; cat /tmp/godot_typing.log; return 1; fi
	echo "--- resource smoke ---"
	"$GODOT_BIN" --headless -s res://bench/resource_smoke.gd 2>&1 | tee -a /tmp/godot_typing.log; EC=${PIPESTATUS[0]}
	if [ "$EC" -ne 0 ]; then echo "Resource smoke failed ($EC)"; grep -E "$ERR_PAT" /tmp/godot_typing.log || true; cat /tmp/godot_typing.log; return "$EC"; fi
	if grep -qE "$ERR_PAT" /tmp/godot_typing.log; then echo "Resource load errors after smoke"; grep -E "$ERR_PAT" /tmp/godot_typing.log; cat /tmp/godot_typing.log; return 1; fi
	echo "typing passed"
}

run_test() {
	echo "=== qa: GUT tests (relax warnings) ==="
	if [ "$HAS_GODOT" -eq 0 ]; then
		echo "::warning::Godot binary not found - skipping GUT tests"
		if [ "${CI:-}" = "true" ]; then return 1; fi
		return 0
	fi
	cp project.godot /tmp/project.godot.qa.bak
	# Portable sed: macOS needs '' arg, Linux does not. Use cp+trick instead of -i.
	sed 's/=2/=1/g' /tmp/project.godot.qa.bak > project.godot
	trap 'mv /tmp/project.godot.qa.bak project.godot 2>/dev/null || true' RETURN
	set +e
	set -o pipefail
	"$GODOT_BIN" --headless -s res://addons/gut/gut_cmdln.gd -gexit -gmaximize -glog=2 -gjunit_xml_file=gut-junit.xml 2>&1 | tee /tmp/gut.log; EXIT=${PIPESTATUS[0]}
	set -e
	mv /tmp/project.godot.qa.bak project.godot
	trap - RETURN
	echo "GUT exit: $EXIT"
	cat /tmp/gut.log | tail -30
	if [ -f gut-junit.xml ]; then
		TESTS=$(grep -o 'tests="[0-9]*"' gut-junit.xml | head -1 | grep -o '[0-9]*' || echo 0)
		echo "JUnit tests: $TESTS"
		if [ "$TESTS" -lt 235 ]; then echo "::error::Test count $TESTS below expected 235"; return 1; fi
	else
		echo "::error::gut-junit.xml not produced"; return 1
	fi
	if [ "$EXIT" -ne 0 ]; then return "$EXIT"; fi
	echo "test passed"
}

run_qa_smoke() {
	echo "=== qa: gameplay smoke (relax warnings) ==="
	if [ "$HAS_GODOT" -eq 0 ]; then
		echo "::warning::Godot binary not found - skipping qa-smoke"
		if [ "${CI:-}" = "true" ]; then return 1; fi
		return 0
	fi
	cp project.godot /tmp/project.godot.qa.bak
	sed 's/=2/=1/g' /tmp/project.godot.qa.bak > project.godot
	trap 'mv /tmp/project.godot.qa.bak project.godot 2>/dev/null || true' RETURN
	set +e
	set -o pipefail
	"$GODOT_BIN" --headless -s res://bench/gameplay_smoke.gd 2>&1 | tee /tmp/qa_smoke.log; EC=${PIPESTATUS[0]}
	set -e
	mv /tmp/project.godot.qa.bak project.godot
	trap - RETURN
	echo "qa-smoke exit: $EC"
	cat /tmp/qa_smoke.log
	if [ "$EC" -ne 0 ]; then echo "::error::qa-smoke exited $EC"; return "$EC"; fi
	if grep -qE "$ERR_PAT_QA" /tmp/qa_smoke.log; then echo "::error::qa-smoke debugger errors"; grep -E "$ERR_PAT_QA" /tmp/qa_smoke.log; return 1; fi
	echo "qa-smoke passed"
}

run_qa_visual() {
	echo "=== qa: visual regression (relax warnings) ==="
	if [ "$HAS_GODOT" -eq 0 ]; then
		echo "::warning::Godot binary not found - skipping qa-visual"
		if [ "${CI:-}" = "true" ]; then return 1; fi
		return 0
	fi
	cp project.godot /tmp/project.godot.qa.bak
	sed 's/=2/=1/g' /tmp/project.godot.qa.bak > project.godot
	trap 'mv /tmp/project.godot.qa.bak project.godot 2>/dev/null || true' RETURN
	set +e
	set -o pipefail
	"$GODOT_BIN" --headless -s res://bench/gameplay_smoke.gd -- --visual-hash 2>&1 | tee /tmp/qa_visual.log; EC=${PIPESTATUS[0]}
	set -e
	mv /tmp/project.godot.qa.bak project.godot
	trap - RETURN
	echo "qa-visual exit: $EC"
	cat /tmp/qa_visual.log
	if [ "$EC" -ne 0 ]; then echo "::error::qa-visual failed — visual drift"; return "$EC"; fi
	echo "qa-visual passed"
}

run_perf() {
	echo "=== qa: perf benches (relax warnings) ==="
	if [ "$HAS_GODOT" -eq 0 ]; then
		echo "::warning::Godot binary not found - skipping perf"
		if [ "${CI:-}" = "true" ]; then return 1; fi
		return 0
	fi
	cp project.godot /tmp/project.godot.qa.bak
	sed 's/=2/=1/g' /tmp/project.godot.qa.bak > project.godot
	set +e
	"$GODOT_BIN" --headless -s res://bench/bench.gd > /tmp/bench_current.log 2>&1
	BENCH_EXIT=$?
	set -e
	cat /tmp/bench_current.log
	python3 << 'PY' || { echo "::error::bench JSON extraction failed"; cat /tmp/bench_current.log; mv /tmp/project.godot.qa.bak project.godot; exit 1; }
import json, pathlib, sys
log = pathlib.Path("/tmp/bench_current.log").read_text(encoding="utf-8", errors="ignore")
found = None
for line in reversed(log.splitlines()):
    s = line.strip()
    if s.startswith("{") and s.endswith("}"):
        try:
            found = json.loads(s)
            break
        except json.JSONDecodeError:
            continue
if found is None:
    print("::error::bench produced no JSON")
    sys.exit(1)
pathlib.Path("bench/current.json").write_text(json.dumps(found))
print(f"extracted: {json.dumps(found)[:400]}")
PY
	cat bench/current.json
	mv /tmp/project.godot.qa.bak project.godot
	if [ "$BENCH_EXIT" -ne 0 ]; then echo "::error::Bench absolute thresholds breached"; return "$BENCH_EXIT"; fi
	python3 bench/check_perf.py --current bench/current.json --baseline bench/baseline.json --mode absolute 2>&1 | tee /tmp/perf_report.log
	echo "perf passed (absolute); regression advisory follows:"
	python3 bench/check_perf.py --current bench/current.json --baseline bench/baseline.json --mode regression 2>&1 | tee -a /tmp/perf_report.log || echo "regression advisory (non-blocking)"
}

case "$STEP_FILTER" in
	--lint-only) run_lint ;;
	--typing-only) run_typing ;;
	--test-only) run_test ;;
	--qa-smoke-only) run_qa_smoke ;;
	--qa-visual-only) run_qa_visual ;;
	--perf-only) run_perf ;;
	"") run_lint; run_typing; run_test; run_qa_smoke; run_qa_visual; run_perf; echo "=== qa: ALL GATES PASSED ===" ;;
	*) echo "Unknown arg: $STEP_FILTER (expected --lint-only|--typing-only|--test-only|--qa-smoke-only|--qa-visual-only|--perf-only)"; exit 1 ;;
esac
