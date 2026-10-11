#!/usr/bin/env bash
# Usage: scripts/tools/start.sh [TASK-ID]      (run by an AGENT in a Claude Code session on the repo; no zips involved)
# Picks work, claims it (committed + pushed so other agents see it), and writes context/<ID>.md for you to read.
#   no ID : resume an abandoned IN-PROGRESS task (checkpoint untouched for STALE_MIN minutes, default 45), else claim the next TODO task
#   ID    : resume/claim that specific task
cd "$(git rev-parse --show-toplevel)"
git config user.name >/dev/null 2>&1 || git config user.name "Moon Agent"; git config user.email >/dev/null 2>&1 || git config user.email "agent@moon.local"
T=scripts/tools/tasks.sh; STALE=${STALE_MIN:-45}
pick() {
  [ -n "$1" ] && { echo "$1"; return; }
  now=$(date +%s)
  grep -E '^- \(' docs/TASKS.md | tr -d '\r' | while read -r line; do
    id=$(echo "$line" | sed -E 's/^- \(([^)]*)\).*/\1/')
    [ "$(bash $T status "$id")" = "IN-PROGRESS" ] || continue
    last=$(git log -1 --format=%ct -- "docs/state/$id.md" 2>/dev/null); last=${last:-0}
    [ $(( (now - last) / 60 )) -ge "$STALE" ] && { echo "$id"; break; }
  done | head -1
}
for attempt in 1 2 3 4; do
  git pull -q --rebase --autostash origin main 2>/dev/null || true
  ID=$(pick "$1"); [ -n "$ID" ] || ID=$(bash $T next)
  [ -n "$ID" ] || { echo "NO_TASKS: nothing claimable (all claimed, done, or waiting on dependencies). Tell the human."; exit 0; }
  if STRICT_PUSH=1 bash scripts/tools/make_context.sh "$ID" >/tmp/.mc.$$ 2>&1; then
    grep -E "^(Claimed|Resuming)" /tmp/.mc.$$
    if grep -q "^Resuming" /tmp/.mc.$$ && [ -f "docs/state/$ID.md" ]; then   # mark the takeover so no other agent grabs it too
      echo "<!-- resumed $(date -u +%FT%TZ) by a new session -->" >> "docs/state/$ID.md"
      git add -A; git commit -qm "[resume] $ID"; git push -q origin HEAD 2>/dev/null || true
    fi
    rm -f /tmp/.mc.$$
    echo "TASK: $ID"; echo "READ NOW: context/$ID.md  (your full briefing; ignore its zip instructions - you save with scripts/tools/save.sh)"
    echo "Task line: $(bash $T line "$ID")"
    exit 0
  fi
  # someone else claimed first (push rejected): drop our claim and try again
  git fetch -q origin main 2>/dev/null; git reset -q --hard origin/main 2>/dev/null; rm -f /tmp/.mc.$$
  [ -n "$1" ] && break
done
echo "Could not claim a task (network or race). Run start.sh again."; exit 1
