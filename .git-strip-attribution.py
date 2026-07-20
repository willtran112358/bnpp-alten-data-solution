#!/usr/bin/env python3
"""Remove Cursor co-author / made-with trailers from commit message (stdin -> stdout)."""
import sys

SKIP_PREFIXES = (
    "co-authored-by:",
    "made-with: cursor",
)

lines = sys.stdin.read().splitlines()
filtered = [
    line
    for line in lines
    if not any(line.lower().startswith(p) for p in SKIP_PREFIXES)
]
while filtered and not filtered[-1].strip():
    filtered.pop()
if filtered:
    sys.stdout.write("\n".join(filtered) + "\n")
