#!/usr/bin/env python3
"""Check that the Windows preset is safe to ship and that its export helper exists."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
preset = (root / "export_presets.cfg").read_text(encoding="utf-8-sig")
script = (root / "scripts/tools/export_windows.sh").read_text(encoding="utf-8-sig")
checks = {
    "Windows Desktop platform": 'platform="Windows Desktop"' in preset,
    "x86_64 target": 'binary_format/architecture="x86_64"' in preset,
    "embedded PCK": "binary_format/embed_pck=true" in preset,
    "no PCK encryption": "encrypt_pck=false" in preset,
    "output outside repository resources": 'export_path="builds/windows/MoonGame.exe"' in preset,
    "both release and debug export modes": "--export-release" in script and "--export-debug" in script,
    "export result must exist": '[[ -s "$OUT" ]]' in script,
    "no credentials in export config": not re.search(r'(?im)^.*(?:password|private_key|signing_key)\s*=\s*"[^"\s]+"', preset),
}
for label, ok in checks.items():
    print(("PASS" if ok else "FAIL") + "  " + label)
if not all(checks.values()):
    raise SystemExit(1)
