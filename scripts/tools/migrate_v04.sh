#!/usr/bin/env bash
# One-time: removes files from the old role-based setup. Safe to run once, then delete.
cd "$(git rev-parse --show-toplevel)"
git rm -rq --ignore-unmatch .claude CLAUDE.md docs/ROLES.md \
  scripts/tools/autosave.sh scripts/tools/resume.sh scripts/tools/finish_task.sh scripts/tools/setup_role.sh scripts/tools/takeover.sh \
  docs/state/lead.md docs/state/assets.md docs/state/slice.md docs/state/mansion.md docs/state/dream.md
echo "Old role files removed. Now: git add -A && git commit -m 'switch to shared task queue' && git push"
