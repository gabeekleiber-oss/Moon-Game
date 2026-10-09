#!/usr/bin/env bash
# Prints everything a fresh agent needs to continue. Runs automatically at session start (Claude Code hook).
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
ROLE=$(cat .role 2>/dev/null || echo "")
echo "=== RESUME BRIEFING ==="
if [ -z "$ROLE" ]; then
  echo "No role set. Ask the human which role you are, then run: scripts/tools/setup_role.sh <lead|assets|slice|mansion|dream>"
  echo "Roles are described in docs/ROLES.md. Also read CLAUDE.md."
  exit 0
fi
echo "Role: $ROLE   Branch: $(git branch --show-current)"
echo
echo "--- Last 8 commits ---"; git log --oneline -8 2>/dev/null
echo
echo "--- Uncommitted changes (should be none after autosave) ---"; git status --short | head -20
echo
echo "--- YOUR CHECKPOINT: docs/state/$ROLE.md ---"
cat "docs/state/$ROLE.md" 2>/dev/null || echo "(no checkpoint yet: create it from docs/state/_TEMPLATE.md)"
echo
echo "--- In-progress tasks (docs/TASKS.md) ---"; grep -n "IN PROGRESS" docs/TASKS.md 2>/dev/null || echo "(none)"
echo
echo "NEXT: read the checkpoint's 'NEXT ACTION', verify the last file mentioned is complete (it may have been cut off mid-write), and continue."
