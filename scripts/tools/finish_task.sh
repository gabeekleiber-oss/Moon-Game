#!/usr/bin/env bash
# Usage: scripts/tools/finish_task.sh "short description"
# Call when a TASK (not just a step) is fully done: rebases on main and publishes to main.
set -e
cd "$(git rev-parse --show-toplevel)"
ROLE=$(cat .role 2>/dev/null || echo unassigned)
git add -A
git diff --cached --quiet || git commit -qm "[$ROLE] ${1:-task complete}"
git fetch -q origin
if ! git rebase origin/main; then
  git rebase --abort
  echo "CONFLICT with main. Do NOT force anything. Note it in docs/HANDOFF.md under 'Questions for Lead' and keep working on your branch."
  exit 1
fi
git push -q -u origin HEAD --force-with-lease
git push -q origin HEAD:main
echo "Published to main: ${1:-task complete}"
