#!/usr/bin/env python3
"""Coverage report + ratchet for GungeonMate.

Parses coverage/lcov.info (produced by `flutter test --coverage`) and
prints per-directory + total line coverage. With --check, fails (exit 1)
when total coverage drops below test/coverage_baseline.txt.
With --update-baseline, writes the current total into that file —
only run this in the same commit that earns the higher coverage.

Usage:
    python tools/coverage_report.py            # report only
    python tools/coverage_report.py --check    # CI gate (exit 1 on drop)
    python tools/coverage_report.py --update-baseline
"""
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LCOV = ROOT / "coverage" / "lcov.info"
BASELINE = ROOT / "test" / "coverage_baseline.txt"


def parse_lcov(path: Path):
    """Return {file: (lines_found, lines_hit)}."""
    per_file = {}
    cur = None
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if line.startswith("SF:"):
            cur = line[3:].replace("\\", "/")
        elif line.startswith("LF:") and cur:
            per_file.setdefault(cur, [0, 0])[0] = int(line[3:])
        elif line.startswith("LH:") and cur:
            per_file[cur][1] = int(line[3:])
    return per_file


def dir_key(path: str) -> str:
    parts = path.split("/")
    if "lib" in parts:
        i = parts.index("lib")
        return "/".join(parts[i : i + 2])
    return path


def main() -> int:
    args = set(sys.argv[1:])
    if not LCOV.exists():
        print(f"error: {LCOV} not found — run `flutter test --coverage` first")
        return 2

    per_file = parse_lcov(LCOV)
    total_lf = sum(v[0] for v in per_file.values())
    total_lh = sum(v[1] for v in per_file.values())
    pct = 100.0 * total_lh / total_lf if total_lf else 0.0

    agg = defaultdict(lambda: [0, 0])
    for f, (lf, lh) in per_file.items():
        k = dir_key(f)
        agg[k][0] += lf
        agg[k][1] += lh

    print(f"{'dir':<28} {'covered':>12} {'total':>8} {'pct':>7}")
    print("-" * 56)
    for k in sorted(agg, key=lambda x: -agg[x][0]):
        lf, lh = agg[k]
        print(f"{k:<28} {lh:>6}/{lf:<5} {lf:>8} {100*lh/lf:>6.1f}%")
    print("-" * 56)
    print(f"{'TOTAL':<28} {total_lh:>6}/{total_lf:<5} {total_lf:>8} {pct:>6.1f}%")

    if "--update-baseline" in args:
        BASELINE.write_text(f"{pct:.1f}\n", encoding="utf-8")
        print(f"\nbaseline updated -> {BASELINE} ({pct:.1f}%)")
        return 0

    if "--check" in args:
        if not BASELINE.exists():
            print(f"\nerror: {BASELINE} missing — run with --update-baseline once")
            return 2
        baseline = float(BASELINE.read_text().strip())
        if pct < baseline - 0.05:  # tiny epsilon for lcov jitter
            print(f"\nCOVERAGE REGRESSION: {pct:.1f}% < baseline {baseline:.1f}%")
            return 1
        print(f"\ncoverage OK: {pct:.1f}% >= baseline {baseline:.1f}%")
    return 0


if __name__ == "__main__":
    sys.exit(main())
