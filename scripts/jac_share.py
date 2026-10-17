#!/usr/bin/env python3
"""Jac share of hand-written code (SOW objective O1). Exits 1 when Jac is under 85%.

Counts non-blank lines by extension in source folders, excluding node_modules, .jac/,
lock files and generated code (mock/mocks.jac). Run from anywhere:
    python scripts/jac_share.py
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
THRESHOLD = 85.0
CODE_EXT = {".jac": "jac", ".ts": "ts", ".tsx": "ts", ".js": "js", ".jsx": "js", ".py": "py", ".css": "css"}
SKIP_DIRS = {".git", ".jac", "node_modules", "dist", "build", "docs", "__pycache__", ".github", "legacy"}
GENERATED = {"mock/mocks.jac"}


def counted_files():
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in CODE_EXT:
            continue
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if rel.as_posix() in GENERATED:
            continue
        yield rel, path


def main():
    totals = {}
    for rel, path in counted_files():
        lines = sum(1 for line in path.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip())
        lang = CODE_EXT[path.suffix]
        totals[lang] = totals.get(lang, 0) + lines
    total = sum(totals.values()) or 1
    share = 100.0 * totals.get("jac", 0) / total
    for lang, n in sorted(totals.items(), key=lambda kv: -kv[1]):
        print(f"{lang:>5}: {n:6d} lines  {100.0 * n / total:5.1f}%")
    print(f"Jac share: {share:.1f}% (threshold {THRESHOLD:.0f}%)")
    sys.exit(0 if share >= THRESHOLD else 1)


if __name__ == "__main__":
    main()
