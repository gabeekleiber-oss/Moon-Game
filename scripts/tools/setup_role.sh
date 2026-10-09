#!/usr/bin/env bash
# Usage: scripts/tools/setup_role.sh <lead|assets|slice|mansion|dream>
# Claims a role, switches to that role's branch (resuming the previous agent's work if it exists).
set -e
cd "$(git rev-parse --show-toplevel)"
ROLE="$1"
case "$ROLE" in lead|assets|slice|mansion|dream) ;; *) echo "Usage: $0 <lead|assets|slice|mansion|dream>"; exit 1;; esac
echo "$ROLE" > .role
git fetch -q origin 2>/dev/null || echo "(offline: using local branches)"
BR="wip/$ROLE"
if git show-ref --verify --quiet "refs/remotes/origin/$BR"; then
  git checkout -q -B "$BR" "origin/$BR"
  echo "Resumed existing branch $BR"
elif git show-ref --verify --quiet "refs/heads/$BR"; then
  git checkout -q "$BR"
else
  git checkout -q -B "$BR"
  echo "Created new branch $BR"
fi
# pick up other roles' finished work, if it applies cleanly
if git show-ref --verify --quiet refs/remotes/origin/main; then
  git rebase -q origin/main 2>/dev/null || { git rebase --abort 2>/dev/null; echo "NOTE: could not rebase on main cleanly; stay on branch, Lead will merge."; }
fi
mkdir -p docs/state
[ -f "docs/state/$ROLE.md" ] || { cp docs/state/_TEMPLATE.md "docs/state/$ROLE.md"; sed -i "s/<ROLE>/$ROLE/" "docs/state/$ROLE.md"; }
echo "Role set: $ROLE  (branch $BR)"
