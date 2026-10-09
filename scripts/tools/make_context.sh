#!/usr/bin/env bash
# Usage: scripts/tools/make_context.sh [TASK-ID]
#   no ID  -> claims the next available task (dependencies done) and builds its bundle
#   ID     -> resumes that task (or claims it if TODO)
# Output: context/<ID>.md  - attach to a new chat and say: "Continue."
set -e
cd "$(git rev-parse --show-toplevel)"
T=scripts/tools/tasks.sh
git pull -q --rebase --autostash origin main 2>/dev/null || echo "(could not pull; using local state)"
ID="$1"
if [ -z "$ID" ]; then ID=$(bash $T next); [ -n "$ID" ] || { echo "No available tasks right now (everything is claimed, done, or waiting on dependencies)."; exit 0; }; fi
ST=$(bash $T status "$ID")
[ -n "$ST" ] || { echo "Unknown task $ID"; exit 1; }
[ "$ST" != "DONE" ] || { echo "Task $ID is already DONE."; exit 0; }
if [ "$ST" = "TODO" ]; then
  bash $T set "$ID" IN-PROGRESS
  if [ ! -f "docs/state/$ID.md" ]; then
    sed "s/<ID>/$ID/g" docs/state/_TEMPLATE.md > "docs/state/$ID.md"
    sed -i.bak "s|^(copy the task line)|$(bash $T line "$ID" | sed 's/[&|\\]/\\&/g')|" "docs/state/$ID.md" && rm -f "docs/state/$ID.md.bak"
  fi
  git add -A; git commit -qm "[claim] $ID"; git push -q origin HEAD 2>/dev/null || true
  echo "Claimed $ID."
else
  echo "Resuming $ID (was $ST)."
fi
mkdir -p context
git rev-parse HEAD > "context/$ID.base"
OUT="context/$ID.md"; CH=$(bash $T field "$ID" ch | tr -d ' ' | tr ',' ' ')
{
  echo "# CONTEXT BUNDLE - task $ID   (repo base commit: $(cat context/$ID.base | cut -c1-8))"
  echo; echo "YOUR TASK: $(bash $T line "$ID")"
  echo; echo "## START HERE (read this, then begin on NEXT ACTION immediately; save early per the RULES)"
  echo "Task checkpoint status and next action:"
  awk '/^STATUS:/{print} /^## NEXT ACTION/{p=1;print;next} /^## /{p=0} p' "docs/state/$ID.md"
  echo; echo "Direction - North star and open questions (docs/DIRECTION.md):"
  awk '/^## Log/{exit} /^## North star|^## Open questions/{p=1} p' docs/DIRECTION.md
  echo "Direction - latest notes from all agents (newest last, last 40):"
  awk '/^## Log/{p=1;next} p' docs/DIRECTION.md | grep '^- ' | tail -40
  echo; echo "## 0. MASTER DOCUMENT (the laws and your operating procedure; docs/MASTER.md wins on process)"
  awk '/^## (2\.|4\.)/{p=1;print;next} /^## /{p=0} p' docs/MASTER.md
  echo; echo "## 1. RULES"; cat docs/CHAT_RULES.md
  echo; echo "## 2. CANON"; cat docs/CANON.md
  echo; echo "## 3. DESIGN (systems, motifs, palettes)"
  awk '/^## (Core systems|Palettes|Motifs|Governing)/{p=1;print;next} /^## /{p=0} p' docs/DESIGN.md
  if [ -n "$CH" ] && [ "$CH" != "-" ]; then
    echo; echo "## 4. YOUR CHAPTER(S) (from docs/CHAPTERS.md)"
    for n in $CH; do awk -v n="$n" '$0 ~ "^"n"\\. \\*\\*" {p=1;print;next} /^[0-9]+\. \*\*/ || /^## /{p=0} p' docs/CHAPTERS.md; done
  fi
  echo; echo "## 5. ARCHITECTURE (contracts)"
  awk '/^## (Chapter contract|Interactable contract|Dialogue JSON|Autoloads|Brief|Performance)/{p=1;print;next} /^## /{p=0} p' docs/ARCHITECTURE.md
  echo; echo "## 6. TASK QUEUE"; cat docs/TASKS.md
  echo; echo "## 7. LATEST HANDOFF NOTES FROM OTHER AGENTS (what's already built)"; head -80 docs/HANDOFF.md
  echo; echo "## 8. YOUR CHECKPOINT (docs/state/$ID.md)"; cat "docs/state/$ID.md"
  echo; echo "## 9. CODE MAP (all scripts: signatures only; ask for any file in full)"
  git ls-files '*.gd' | sort | while read f; do
    echo "### $f ($(wc -l < "$f") lines)"; grep -E '^(##|class_name|extends|signal |func |const |enum |@export)' "$f" | head -40
  done
  echo; echo "## 10. OTHER FILES"
  git ls-files | grep -v -E '\.gd$|^docs/|\.gitkeep$|\.import$|^\.' | sort | while read f; do echo "$f ($(wc -l < "$f" 2>/dev/null || echo ?) lines)"; done
  find . -name '*.incoming' -not -path './.git/*' 2>/dev/null | sed 's|^\./||' | while read f; do echo "CONFLICT TO MERGE FIRST: $f"; done
  echo; echo "## 11. FILES IN FLIGHT (full contents, from your checkpoint)"
  awk '/^## FILES IN FLIGHT/{p=1;next} /^## /{p=0} p && /^- /{sub(/^- /,"");sub(/ - .*/,"");print}' "docs/state/$ID.md" | while read f; do
    if [ -f "$f" ]; then echo; echo "### $f"; echo '```'; head -400 "$f"; echo '```'; fi
  done
} > "$OUT"
WIN=$(cygpath -w "$(pwd)/$OUT" 2>/dev/null || echo "$(pwd)/$OUT")
echo
echo "=============================================================="
echo "  TASK $ID is ready."
echo
echo "  ATTACH THIS ONE FILE to a new chat (nothing else):"
echo "      $WIN"
echo "  Then type:   Continue."
echo
echo "  (~$(( $(wc -c < "$OUT") / 4 )) tokens. It already contains the rules, canon, direction and code map.)"
echo "  When the chat gives you zip file(s), apply each, in order:"
echo "      bash scripts/tools/apply_output.sh /c/Users/gabek/Downloads/<zip name>"
echo "=============================================================="
command -v explorer.exe >/dev/null 2>&1 && explorer.exe /select,"$WIN" >/dev/null 2>&1 || true
