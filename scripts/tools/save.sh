#!/usr/bin/env bash
# Usage: scripts/tools/save.sh "what you just did" [TASK-ID]       (run by an AGENT; replaces zips)
# Publishes your work to the shared repo NOW: updates notes/proposals/DONE from your checkpoint, commits, rebases on others' work, pushes.
# Call it after EVERY small step and before any long piece of work. Anything not saved is lost if your usage runs out.
# docs/TASKS.md is script-managed and is the file agents collide on most (everyone flips a status line): conflicts there are resolved
# automatically (take upstream, then finalize.sh re-applies this task's DONE/proposals, which is idempotent). Any other conflict is yours to fix.
cd "$(git rev-parse --show-toplevel)"
git config user.name >/dev/null 2>&1 || git config user.name "Moon Agent"; git config user.email >/dev/null 2>&1 || git config user.email "agent@moon.local"
MSG="${1:-progress}"; ID="${2:-$(cat context/.current 2>/dev/null)}"
[ -n "$ID" ] || { echo "No task id: run scripts/tools/start.sh first (or pass the ID as 2nd argument)."; exit 1; }
bash scripts/tools/finalize.sh "$ID"
git add -A
git diff --cached --quiet || git commit -qm "[$ID] $MSG"

rebase_active() { [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; }

# Resolve a rebase that stopped only on docs/TASKS.md; returns 0 when the rebase finished.
auto_resolve() {
  local guard=0
  while rebase_active && [ $guard -lt 30 ]; do
    guard=$((guard+1))
    local conflicted; conflicted="$(git diff --name-only --diff-filter=U)"
    [ "$conflicted" = "docs/TASKS.md" ] || return 1
    git checkout --ours docs/TASKS.md 2>/dev/null && git add docs/TASKS.md
    if git diff --cached --quiet; then git rebase --skip >/dev/null 2>&1 || true
    else GIT_EDITOR=true git rebase --continue >/dev/null 2>&1 || true; fi
  done
  ! rebase_active
}

for i in 1 2 3 4 5; do
  if ! git pull -q --rebase --autostash origin main 2>/tmp/.sv.$$; then
    if rebase_active && auto_resolve; then
      bash scripts/tools/finalize.sh "$ID" >/dev/null   # re-apply this task's DONE / proposals on top of upstream's TASKS.md
      git add -A
      git diff --cached --quiet || git commit -qm "[$ID] $MSG (tasks re-applied)"
    else
      echo "!! MERGE CONFLICT while rebasing. Fix it:"; git status --short | grep -E '^(UU|AA|DU|UD)'
      echo "   Edit each conflicted file (keep BOTH sides' intent), then: git add <file> && GIT_EDITOR=true git rebase --continue && bash scripts/tools/save.sh \"\$MSG\""
      cat /tmp/.sv.$$ 2>/dev/null | tail -3; rm -f /tmp/.sv.$$; exit 2
    fi
  fi
  if git push -q origin HEAD 2>/dev/null; then echo "SAVED to GitHub: [$ID] $MSG"; rm -f /tmp/.sv.$$; exit 0; fi
  sleep $((i*2))
done
echo "!! Push failed 5 times (network/auth?). Your work is committed locally; retry save.sh shortly."
echo "   If it keeps failing with 403: the token/login can read but not write this repo (needs Contents: read+write)."; exit 1
