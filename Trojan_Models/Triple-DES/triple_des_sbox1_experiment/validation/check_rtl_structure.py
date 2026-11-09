#!/usr/bin/env python3
"""Static checks for matched Triple-DES RTL source sets (not a substitute for synthesis)."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
RESERVED = {
    "module", "function", "task", "if", "for", "while", "case", "casex", "casez",
    "assign", "always", "initial", "begin", "end", "endcase", "endfunction",
    "endtask", "endmodule", "generate", "endgenerate", "else", "repeat", "forever",
}


def uncomment(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", " ", text)


def check_filelist(name: str) -> None:
    entries = [line.strip() for line in (ROOT / "filelists" / name).read_text().splitlines()
               if line.strip() and not line.lstrip().startswith("#")]
    files = [ROOT / entry for entry in entries]
    for path in files:
        if not path.is_file():
            raise SystemExit(f"FAIL: missing file in {name}: {path}")

    modules: dict[str, Path] = {}
    parsed: list[tuple[Path, str]] = []
    for path in files:
        text = uncomment(path.read_text(encoding="utf-8"))
        parsed.append((path, text))
        for mod in re.findall(r"\bmodule\s+([A-Za-z_]\w*)", text):
            if mod in modules:
                raise SystemExit(f"FAIL: duplicate module {mod} in {name}")
            modules[mod] = path
        if re.search(r"<=\s*#\s*\d+", text) or re.search(r"\binitial\b", text):
            raise SystemExit(f"FAIL: simulation-only delay/initial block in synth RTL: {path}")

    missing = set()
    for path, text in parsed:
        for kind, _instance in re.findall(r"\b([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(", text):
            if kind not in RESERVED and kind not in modules:
                missing.add(kind)
    if missing:
        raise SystemExit(f"FAIL: unresolved module references in {name}: {sorted(missing)}")
    if "des3" not in modules:
        raise SystemExit(f"FAIL: top-level des3 not present in {name}")
    print(f"PASS: {name}: {len(files)} files, {len(modules)} modules, no unresolved instances or #delay/initial blocks")


for name in (
    "area_opt_golden.f", "area_opt_variant.f",
    "perf_opt_golden.f", "perf_opt_variant.f",
):
    check_filelist(name)

# The functional source-tree difference must be limited to the target S-Box.
g = ROOT / "golden_model/rtl_triple-des"
m = ROOT / "sbox1_variant/rtl_triple-des"
changed = []
for gp in sorted(g.rglob("*.v")):
    rel = gp.relative_to(g)
    mp = m / rel
    if not mp.exists() or gp.read_bytes() != mp.read_bytes():
        changed.append(rel.as_posix())
if changed != ["common/sbox1.v"]:
    raise SystemExit(f"FAIL: expected only common/sbox1.v to differ; got {changed}")
print("PASS: Golden and variant RTL differ only in common/sbox1.v")
