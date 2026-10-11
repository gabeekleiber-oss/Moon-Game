#!/usr/bin/env bash
# Usage: bash scripts/tools/shot.sh res://tests/_something_shot.tscn [-- user args]    Renders a scene in a virtual display (software GL) so a screenshot script can save a PNG.
# Gotchas learned the hard way: headless can't draw (use this, not --headless); the Cutscene autoload owns a camera, so shot scripts must call cam.make_current().
cd "$(git rev-parse --show-toplevel)" || exit 1
GODOT="$(bash scripts/tools/ensure_godot.sh)" || exit 1
command -v xvfb-run >/dev/null 2>&1 || { echo "xvfb-run missing (apt install xvfb)"; exit 1; }
SCENE="$1"; shift
xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . --rendering-method gl_compatibility --resolution 1000x700 "$SCENE" "$@" 2>&1 | grep -v -E 'ALSA|audio|status < 0|V-Sync|vsync'
