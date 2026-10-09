#!/usr/bin/env bash
# Usage: scripts/tools/finalize.sh <TASK-ID>
# Reads docs/state/<ID>.md and updates the shared files: DONE -> TASKS + HANDOFF, NOTES FOR DIRECTION -> DIRECTION.md, PROPOSED TASKS -> TASKS.md.
# Safe to run repeatedly. Called by apply_output.sh (zip mode) and save.sh (git mode).
cd "$(git rev-parse --show-toplevel)"
ID="$1"; [ -n "$ID" ] || { echo "Usage: $0 <TASK-ID>"; exit 1; }
# task completion
if [ -f "docs/state/$ID.md" ] && grep -q '^STATUS: *DONE' "docs/state/$ID.md"; then
  if [ "$(bash scripts/tools/tasks.sh status "$ID")" != "DONE" ]; then
    bash scripts/tools/tasks.sh set "$ID" DONE
    { echo; echo "<!-- done:$ID -->"; echo "## $ID done ($(date +%F))"; awk '/^## HANDOFF NOTE/{p=1;next} /^## /{p=0} p' "docs/state/$ID.md"; } > .handoff_new
    { head -2 docs/HANDOFF.md; cat .handoff_new; tail -n +3 docs/HANDOFF.md; } > .handoff_merged && mv .handoff_merged docs/HANDOFF.md; rm -f .handoff_new
    echo ">>> TASK $ID MARKED DONE; handoff note published."
  fi
fi
# agent notes -> shared DIRECTION log (only lines not already there)
if [ -f "docs/state/$ID.md" ]; then
  awk '/^## NOTES FOR DIRECTION/{p=1;next} /^## /{p=0} p' "docs/state/$ID.md" | tr -d '\r' | sed -E 's/^[[:space:]]*-[[:space:]]*//' | grep -v '^[[:space:]]*$' | while IFS= read -r note; do
    grep -qF -- "- [$ID] $note" docs/DIRECTION.md 2>/dev/null || { echo "- [$ID] $note" >> docs/DIRECTION.md; echo ">>> Direction note added: $note" | cut -c1-110; }
  done
fi
# agent-proposed tasks -> shared queue (strict format, new IDs only)
if [ -f "docs/state/$ID.md" ]; then
  awk '/^## PROPOSED TASKS/{p=1;next} /^## /{p=0} p' "docs/state/$ID.md" | tr -d '\r' | grep -E '^- \(P-[A-Za-z0-9-]+\) [^|]+ \| needs: [^|]+ \| ch: [^|]+ \| TODO$' | while read -r line; do
    PID=$(echo "$line" | sed -E 's/^- \(([^)]*)\).*/\1/')
    if [ -z "$(bash scripts/tools/tasks.sh status "$PID")" ]; then
      grep -q '^## Proposed by agents' docs/TASKS.md || printf '\n## Proposed by agents (claimable like any task)\n' >> docs/TASKS.md
      echo "$line" >> docs/TASKS.md; echo ">>> New task queued: $PID"
    fi
  done
fi
