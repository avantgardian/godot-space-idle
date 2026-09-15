#!/usr/bin/env python3
"""
CI perf gate: compare current bench results vs baseline.json.

Usage:
  python3 bench/check_perf.py --current bench/current.json
  python3 bench/check_perf.py --current <(godot --headless -s res://bench/bench.gd 2>&1 | grep '^{')
  python3 bench/check_perf.py --current bench/current.json --mode absolute   # required, blocks PR
  python3 bench/check_perf.py --current bench/current.json --mode regression # advisory, warning only

Exit 0 = pass, 1 = fail.
Absolute thresholds (from #295 / #296) — REQUIRED, block PR (#310):
  trail_per_frame_ms_8x <= 0.08 ms
  starfield_generate_ms <= 150 ms
Regression > 30% vs baseline — ADVISORY only (#310, runner variance 70 ms local vs 124 ms CI).

If baseline.json missing, only absolute thresholds are checked.
"""
import argparse
import json
import sys
from pathlib import Path

ABS_THRESHOLDS = {
    "trail_per_frame_ms_8x": 0.08,
    "starfield_generate_ms": 150.0,
}

REGRESSION_PCT = 30.0  # fail if >30% slower than baseline


def load_json(path: Path) -> dict:
    text = path.read_text(encoding="utf-8").strip()
    # bench.gd prints a single JSON object on one line; handle surrounding logs
    for line in reversed(text.splitlines()):
        line = line.strip()
        if line.startswith("{") and line.endswith("}"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                continue
    return json.loads(text)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--current", required=True, help="Path to current bench JSON output")
    ap.add_argument("--baseline", default="bench/baseline.json", help="Path to baseline.json")
    ap.add_argument("--regression-pct", type=float, default=REGRESSION_PCT)
    ap.add_argument(
        "--mode",
        choices=["all", "absolute", "regression"],
        default="all",
        help="Gate mode: all (default, backward compat), absolute (required) or regression (advisory, #310)",
    )
    args = ap.parse_args()

    current = load_json(Path(args.current))
    print(f"[check_perf] current: {json.dumps(current, indent=2)}")

    baseline = None
    bpath = Path(args.baseline)
    if bpath.exists():
        baseline = json.loads(bpath.read_text(encoding="utf-8"))
        print(f"[check_perf] baseline: {json.dumps(baseline, indent=2)}")
    else:
        print(f"[check_perf] no baseline at {bpath}, skipping regression check")

    failures: list[str] = []

    # Absolute thresholds — required gate (#310)
    if args.mode in ("all", "absolute"):
        for key, limit in ABS_THRESHOLDS.items():
            if key in current:
                val = float(current[key])
                status = "OK" if val <= limit else "FAIL"
                print(f"[check_perf] abs  {key}: {val:.4f} vs {limit:.4f} [{status}]")
                if val > limit:
                    failures.append(f"{key} {val:.4f} > {limit:.4f}")
    else:
        print("[check_perf] skipping absolute thresholds (mode=regression)")

    # Regression vs baseline — advisory only (#310)
    if baseline is not None and args.mode in ("all", "regression"):
        for key in ["trail_per_frame_ms_8x", "starfield_generate_ms", "nbody_avg_us_per_frame", "collision_avg_us"]:
            if key in current and key in baseline:
                cur = float(current[key])
                base = float(baseline[key])
                if base == 0:
                    continue
                pct = (cur - base) / base * 100.0
                status = "OK" if pct <= args.regression_pct else "FAIL"
                print(f"[check_perf] regr {key}: {cur:.4f} vs {base:.4f} ({pct:+.1f}%) [{status}]")
                if pct > args.regression_pct:
                    failures.append(f"{key} regression {pct:.1f}% > {args.regression_pct:.1f}%")
    elif args.mode == "absolute":
        print("[check_perf] skipping regression check (mode=absolute)")
    elif baseline is None:
        pass  # already logged missing baseline

    if failures:
        print("[check_perf] FAIL:", "; ".join(failures))
        return 1
    print("[check_perf] PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
