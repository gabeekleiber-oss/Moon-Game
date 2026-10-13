#!/usr/bin/env python3
"""Fail closed if an external asset is present without an explicit license record."""
from __future__ import annotations
import re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
LICENSES = ASSETS / "LICENSES.md"
ALLOWED = ("CC0", "CC-0", "CC BY", "CC-BY", "OFL", "PUBLIC DOMAIN", "PUBLIC-DOMAIN")
IGNORE_PARTS = {"_inbox", "_done", ".git"}
IGNORE_NAMES = {".gitkeep", "README.md", "LICENSES.md"}

def rows(path: Path):
    if not path.is_file():
        return []
    result = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|") or line.lstrip("| ").startswith("---"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) >= 6 and cells[0].lower() != "request":
            result.append(cells)
    return result

def main() -> int:
    errors = []
    license_rows = rows(LICENSES)
    if not LICENSES.exists():
        errors.append("assets/LICENSES.md is missing")
    licensed_paths = set()
    for row in license_rows:
        files_cell, source_cell, license_cell = row[2], row[3], row[4].upper().strip()
        licensed_paths.update(p.strip() for p in re.findall(r"assets/[A-Za-z0-9_./ -]+", files_cell))
        normalized = license_cell.replace("-", " ").replace("_", " ")
        is_cc0 = normalized in {"CC0", "CC 0", "CREATIVE COMMONS ZERO", "PUBLIC DOMAIN"}
        is_ofl = normalized == "OFL" or normalized.startswith("OFL ") or normalized.startswith("SIL OPEN FONT LICENSE")
        is_cc_by = "CC BY" in normalized and "NC" not in normalized and "ND" not in normalized
        if not (is_cc0 or is_ofl or is_cc_by):
            errors.append(f"{row[0]} has an unapproved or unverified license: {row[4]}")
        if not re.search(r"https?://", source_cell, re.IGNORECASE):
            errors.append(f"{row[0]} is missing the exact source URL in the source / author note")
        if is_cc_by and not re.search(r"author\s*:", source_cell, re.IGNORECASE):
            errors.append(f"{row[0]} uses CC-BY but does not record author credit")
    if ASSETS.exists():
        for path in ASSETS.rglob("*"):
            if not path.is_file() or path.name in IGNORE_NAMES:
                continue
            if any(part in IGNORE_PARTS for part in path.relative_to(ASSETS).parts):
                continue
            if path.suffix.lower() in {".zip", ".7z", ".rar", ".txt"}:
                errors.append(f"unimported or sidecar file remains in assets/: {path.relative_to(ROOT)}")
                continue
            rel = path.relative_to(ROOT).as_posix()
            if rel not in licensed_paths:
                errors.append(f"asset has no license row: {rel}")
    if errors:
        print(f"ASSET LICENSE CHECK: FAIL ({len(errors)} issue(s))")
        for error in errors:
            print(" - " + error)
        return 1
    print(f"ASSET LICENSE CHECK: PASS ({len(licensed_paths)} licensed file path(s))")
    return 0

if __name__ == "__main__":
    sys.exit(main())
