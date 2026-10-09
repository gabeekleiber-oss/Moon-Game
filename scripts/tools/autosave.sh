#!/usr/bin/env bash
# Autosave: commit everything and push in the background. Runs after EVERY file edit (Claude Code hook).
# Never fails the caller. Safe if offline (commit stays local; next push sends it).
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
ROLE=$(cat .role 2>/dev/null || echo unassigned)
git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -qm "[wip:$ROLE] autosave $(date +%H:%M:%S)" >/dev/null 2>&1
fi
( git push -q -u origin HEAD >/dev/null 2>&1 & ) 2>/dev/null
exit 0
