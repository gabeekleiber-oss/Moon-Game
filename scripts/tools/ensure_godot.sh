#!/usr/bin/env bash
# Prints the path of a Godot 4.3 executable, downloading the Linux build to ~/.cache if none is installed.
# Order: $GODOT, `godot` / `godot4` on PATH, cached download. Usage: GODOT=$(bash scripts/tools/ensure_godot.sh)
VER="${GODOT_VERSION:-4.3-stable}"
[ -n "$GODOT" ] && [ -x "$GODOT" ] && { echo "$GODOT"; exit 0; }
for c in godot godot4; do command -v "$c" >/dev/null 2>&1 && { command -v "$c"; exit 0; }; done
DIR="$HOME/.cache/godot-$VER"; BIN="$DIR/Godot_v${VER}_linux.x86_64"
[ -x "$BIN" ] && { echo "$BIN"; exit 0; }
[ "$(uname -s)" = "Linux" ] || { echo "Godot not found: install Godot 4.3 or set GODOT=/path/to/godot" >&2; exit 1; }
mkdir -p "$DIR" && cd "$DIR" || exit 1
curl -sfL -o godot.zip "https://github.com/godotengine/godot/releases/download/$VER/Godot_v${VER}_linux.x86_64.zip" \
  && unzip -qo godot.zip && rm -f godot.zip && chmod +x "$BIN" || { echo "Could not download Godot $VER (network blocked? set GODOT=...)" >&2; exit 1; }
echo "$BIN"
