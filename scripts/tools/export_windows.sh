#!/usr/bin/env bash
# Export a self-contained Windows x86_64 game binary using Godot's installed export templates.
# Usage: GODOT=/path/to/godot bash scripts/tools/export_windows.sh [debug|release] [output.exe]
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
MODE="${1:-release}"
if [[ "$MODE" != "release" && "$MODE" != "debug" ]]; then
  echo "Usage: export_windows.sh [debug|release] [output.exe]" >&2; exit 2
fi
OUT="${2:-builds/windows/MoonGame.exe}"
[[ "$OUT" == *.exe ]] || { echo "Output must end in .exe" >&2; exit 2; }
GODOT="$(bash scripts/tools/ensure_godot.sh)" || exit 1
[[ -f export_presets.cfg ]] || { echo 'Missing export_presets.cfg' >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
"$GODOT" --headless --path . --import
if [[ "$MODE" == "release" ]]; then
  "$GODOT" --headless --path . --export-release 'Windows Desktop' "$OUT"
else
  "$GODOT" --headless --path . --export-debug 'Windows Desktop' "$OUT"
fi
[[ -s "$OUT" ]] || { echo "Export did not create $OUT (install matching Godot export templates)" >&2; exit 1; }
echo "Windows export ready: $OUT"
