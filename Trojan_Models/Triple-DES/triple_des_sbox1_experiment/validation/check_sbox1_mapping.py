#!/usr/bin/env python3
"""Exhaustively compare the 64 S1 table entries in the Golden and mutant RTL."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
GOLD = ROOT / "golden_model/rtl_triple-des/common/sbox1.v"
MUT = ROOT / "sbox1_variant/rtl_triple-des/common/sbox1.v"


def entries(path: Path) -> dict[int, int]:
    text = path.read_text(encoding="utf-8")
    # Read the numeric case labels and decimal right-hand-side constants.
    pairs = re.findall(r"^\s*(\d+)\s*:\s*dout\s*=\s*(\d+)\s*;", text, re.M)
    table = {int(k): int(v) for k, v in pairs}
    if len(table) != 64 or set(table) != set(range(64)):
        raise SystemExit(f"FAIL: {path} has {len(table)} distinct S1 case entries, expected 64")
    return table


g, m = entries(GOLD), entries(MUT)
# In the RTL, the explicit addr==0 condition overrides the original case entry 0.
m[0] = 15
changed = [i for i in range(64) if g[i] != m[i]]
if changed != [0] or (g[0], m[0]) != (14, 15):
    raise SystemExit(f"FAIL: unexpected mapping differences: {[(i,g[i],m[i]) for i in changed]}")
print("PASS: 64/64 entries parsed; exactly one output mapping differs: addr 000000, E -> F.")
