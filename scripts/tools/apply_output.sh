#!/usr/bin/env bash
# Usage: scripts/tools/apply_output.sh <TASKID_step_NN.zip>
# Merges an agent's zip into the repo (3-way merge if others changed the same file), updates task status, commits, pushes.
set -e
ZIP="$1"; [ -f "$ZIP" ] && ZIP="$(cd "$(dirname "$ZIP")" && pwd)/$(basename "$ZIP")"  # absolute path, since we cd below
cd "$(git rev-parse --show-toplevel)"
[ -f "$ZIP" ] || { echo "Usage: $0 <TASKID_step_NN.zip>"; exit 1; }
ID=$(basename "$ZIP" .zip); ID="${ID%%_step*}"
bash scripts/tools/tasks.sh status "$ID" >/dev/null 2>&1 || true
[ -n "$(bash scripts/tools/tasks.sh status "$ID")" ] || { echo "Zip name must start with a task ID, e.g. F-01_step_01.zip"; exit 1; }
git add -A; git diff --cached --quiet || git commit -qm "[local] pending changes"
git pull -q --rebase --autostash origin main 2>/dev/null || echo "(could not pull; merging against local state)"
BASE=$(cat "context/$ID.base" 2>/dev/null || git rev-parse HEAD)
TMP=$(mktemp -d)
# Git Bash on Windows has no `unzip`: try unzip, then python, then PowerShell
(if command -v unzip >/dev/null 2>&1; then unzip -q "$ZIP" -d "$TMP"
elif command -v python3 >/dev/null 2>&1 && python3 -c 1 2>/dev/null; then python3 -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$ZIP" "$TMP"
elif command -v python >/dev/null 2>&1 && python -c 1 2>/dev/null; then python -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$ZIP" "$TMP"
elif command -v powershell.exe >/dev/null 2>&1; then powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '$(cygpath -w "$ZIP")' -DestinationPath '$(cygpath -w "$TMP")' -Force"
else echo "Cannot unzip: no unzip, python or powershell found."; exit 1; fi) || { echo "Could not read that zip (corrupt or incomplete download). Download it again."; exit 1; }
[ -n "$(ls -A "$TMP")" ] || { echo "Zip was empty or could not be extracted."; exit 1; }
SRC="$TMP"
if [ "$(ls -A "$TMP" | wc -l)" = "1" ]; then
  ONLY="$TMP/$(ls "$TMP")"
  if [ -d "$ONLY" ] && { [ -e "$ONLY/project.godot" ] || [ -d "$ONLY/docs" ] && [ "$(basename "$ONLY")" != "docs" ]; }; then SRC="$ONLY"; fi
  [ "$(basename "$ONLY")" = "game-project" ] && SRC="$ONLY"
fi
CONFLICTS=""
cd "$SRC"; FILES=$(find . -type f | sed 's|^\./||' | sort); cd - >/dev/null
for f in $FILES; do
  case "$f" in
    docs/TASKS.md|docs/HANDOFF.md|context/*) echo "skip (scripts own this): $f"; continue;;
    docs/state/*) [ "$f" = "docs/state/$ID.md" ] || { echo "skip (not your checkpoint): $f"; continue; };;
  esac
  mkdir -p "$(dirname "$f")"
  if [ ! -f "$f" ]; then cp "$SRC/$f" "$f"; echo "new:      $f"; continue; fi
  if git cat-file -e "$BASE:$f" 2>/dev/null; then
    if git diff --quiet "$BASE" HEAD -- "$f"; then cp "$SRC/$f" "$f"; echo "updated:  $f"; continue; fi
    git show "$BASE:$f" > "$TMP/.base"
  else
    : > "$TMP/.base"
  fi
  if grep -qI . "$SRC/$f" 2>/dev/null; then
    cp "$f" "$TMP/.cur"
    MFLAG=""; [ "$f" = "autoload/events.gd" ] && MFLAG="--union"   # append-only signal bus: keep both sides' additions
    if git merge-file -p $MFLAG "$TMP/.cur" "$TMP/.base" "$SRC/$f" > "$TMP/.merged"; then
      cp "$TMP/.merged" "$f"; echo "merged:   $f (others changed it too; auto-merged)"
    else
      cp "$SRC/$f" "$f.incoming"; CONFLICTS="$CONFLICTS $f"; echo "CONFLICT: $f  (kept current; yours saved as $f.incoming)"
    fi
  else
    cp "$SRC/$f" "$f"; echo "updated (binary): $f"
  fi
done
rm -rf "$TMP"
bash scripts/tools/finalize.sh "$ID"   # notes -> DIRECTION, proposed tasks -> queue, DONE -> handoff
git add -A
if git diff --cached --quiet; then echo "No changes."; else
  git commit -qm "[$ID] $(basename "$ZIP" .zip)"
  git push -q origin HEAD 2>/dev/null && echo "Committed + pushed." || echo "Committed locally (push failed: run 'git push')."
fi
[ -z "$CONFLICTS" ] || echo "!! Conflicts in:$CONFLICTS  -> next chat's first step will merge them."
