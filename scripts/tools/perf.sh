#!/usr/bin/env bash
# Usage: bash scripts/tools/perf.sh [scene.tscn ...]     Frame-time probe over scenes (default: the act scenes + lighting test room).
# Reports go to /tmp/perf/<scene>.json. With xvfb (software GL) only draw calls and scene stats are meaningful; run on a real GPU for ms.
# Exit 1 if any scene is over its draw-call budget or SceneStats limits.
cd "$(git rev-parse --show-toplevel)" || exit 1
GODOT="$(bash scripts/tools/ensure_godot.sh)" || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
if [ $# -eq 0 ]; then set -- res://scenes/lighting/lighting_test_room.tscn $(ls scenes/acts/*/*.tscn | sed 's#^#res://#'); fi
RUN=("$GODOT" --path . --rendering-method gl_compatibility --resolution 1000x700)
[ -n "$DISPLAY" ] || RUN=(xvfb-run -a -s "-screen 0 1280x800x24" "${RUN[@]}")
bad=0
for s in "$@"; do
  case "$s" in res://*) ;; *) s="res://${s#./}" ;; esac
  name=$(basename "$s" .tscn); out="/tmp/perf/$name.json"; rm -f "$out"
  "${RUN[@]}" res://scenes/perf/frame_probe.tscn -- --scene="$s" --out="$out" 2>&1 | grep -E '^PERF|^FAIL|SCRIPT ERROR'
  if [ ! -f "$out" ]; then echo "FAIL no report for $s"; bad=1; continue; fi
  python3 - "$out" <<'PY' || bad=1
import json,sys
r=json.load(open(sys.argv[1])); sv=r["stats_violations"]
if r["over_draw_budget"] or sv: print("OVER BUDGET", r["scene"], r["max_draw_calls"], sv); sys.exit(1)
PY
done
[ $bad -eq 0 ] && echo "PERF OK" || { echo "PERF FAILED"; exit 1; }
