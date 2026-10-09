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
git pull -q --rebase origin main 2>/dev/null || echo "(could not pull; merging against local state)"
BASE=$(cat "context/$ID.base" 2>/dev/null || git rev-parse HEAD)
TMP=$(mktemp -d); unzip -q "$ZIP" -d "$TMP"
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
    if git merge-file -p "$TMP/.cur" "$TMP/.base" "$SRC/$f" > "$TMP/.merged"; then
      cp "$TMP/.merged" "$f"; echo "merged:   $f (others changed it too; auto-merged)"
    else
      cp "$SRC/$f" "$f.incoming"; CONFLICTS="$CONFLICTS $f"; echo "CONFLICT: $f  (kept current; yours saved as $f.incoming)"
    fi
  else
    cp "$SRC/$f" "$f"; echo "updated (binary): $f"
  fi
done
rm -rf "$TMP"
# task completion
if [ -f "docs/state/$ID.md" ] && grep -q '^STATUS: *DONE' "docs/state/$ID.md"; then
  if [ "$(bash scripts/tools/tasks.sh status "$ID")" != "DONE" ]; then
    bash scripts/tools/tasks.sh set "$ID" DONE
    { echo; echo "<!-- done:$ID -->"; echo "## $ID done ($(date +%F))"; awk '/^## HANDOFF NOTE/{p=1;next} /^## /{p=0} p' "docs/state/$ID.md"; } > .handoff_new
    { head -2 docs/HANDOFF.md; cat .handoff_new; tail -n +3 docs/HANDOFF.md; } > .handoff_merged && mv .handoff_merged docs/HANDOFF.md; rm -f .handoff_new
    echo ">>> TASK $ID MARKED DONE; handoff note published."
  fi
fi
git add -A
if git diff --cached --quiet; then echo "No changes."; else
  git commit -qm "[$ID] $(basename "$ZIP" .zip)"
  git push -q origin HEAD 2>/dev/null && echo "Committed + pushed." || echo "Committed locally (push failed: run 'git push')."
fi
[ -z "$CONFLICTS" ] || echo "!! Conflicts in:$CONFLICTS  -> next chat's first step will merge them."
