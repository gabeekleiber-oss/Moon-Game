#!/usr/bin/env bash
# Usage: scripts/tools/apply_output.sh <downloaded.zip> [role]
# Unpacks an agent's output zip into the repo, commits, and pushes.
set -e
cd "$(git rev-parse --show-toplevel)"
ZIP="$1"; ROLE="${2:-$(cat .role 2>/dev/null || echo agent)}"
[ -f "$ZIP" ] || { echo "Usage: $0 <file.zip> [role]"; exit 1; }
TMP=$(mktemp -d); unzip -q "$ZIP" -d "$TMP"
# strip a single wrapper folder ONLY if it is the whole project (contains project.godot) or is named game-project
SRC="$TMP"
if [ "$(ls -A "$TMP" | wc -l)" = "1" ]; then
  ONLY="$TMP/$(ls "$TMP")"
  if [ -d "$ONLY" ] && { [ -e "$ONLY/project.godot" ] || [ "$(basename "$ONLY")" = "game-project" ]; }; then SRC="$ONLY"; fi
fi
echo "Files in this delivery:"; (cd "$SRC" && find . -type f | sed 's|^\./||' | sort)
cp -r "$SRC"/. .
rm -rf "$TMP"
git add -A
git diff --cached --quiet && { echo "No changes."; exit 0; }
git commit -qm "[$ROLE] $(basename "$ZIP" .zip)"
git push -q origin HEAD 2>/dev/null && echo "Committed + pushed." || echo "Committed locally (push failed or no remote)."
