#!/usr/bin/env bash
# Usage: scripts/tools/make_context.sh <lead|assets|slice|mansion|dream>
# Builds context/<role>_context.md: attach it (or paste it) at the start of a new chat. Keeps token use small.
set -e
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROLE="$1"
case "$ROLE" in
  lead)    CH="";            DIRS="docs autoload scripts scenes/main scenes/ui scenes/fx";;
  assets)  CH="10 11";       DIRS="scenes/props scenes/characters scenes/fx assets/audio scenes/chapters/ch10_* scenes/chapters/ch11_*";;
  slice)   CH="1 2 3";       DIRS="scenes/chapters/ch01_* scenes/chapters/ch02_* scenes/chapters/ch03_*";;
  mansion) CH="4 5 6 7";     DIRS="scenes/chapters/ch04_* scenes/chapters/ch05_* scenes/chapters/ch06_* scenes/chapters/ch07_*";;
  dream)   CH="8 9";         DIRS="scenes/chapters/ch08_* scenes/chapters/ch09_*";;
  *) echo "Usage: $0 <lead|assets|slice|mansion|dream>"; exit 1;;
esac
mkdir -p context
OUT="context/${ROLE}_context.md"
{
  echo "# CONTEXT BUNDLE for role: $ROLE  ($(date +%F\ %H:%M))"
  echo; echo "## 1. RULES"; cat docs/CHAT_RULES.md
  echo; echo "## 2. CANON"; cat docs/CANON.md
  echo; echo "## 3. ROLES"; cat docs/ROLES.md
  if [ "$ROLE" = "lead" ]; then
    echo; echo "## 4. DESIGN"; cat docs/DESIGN.md
    echo; echo "## 5. ARCHITECTURE"; cat docs/ARCHITECTURE.md
    echo; echo "## 6. CHAPTERS"; cat docs/CHAPTERS.md
  else
    echo; echo "## 4. DESIGN (systems + palettes)"
    awk '/^## (Core systems|Palettes|Motifs|Governing)/{p=1;print;next} /^## /{p=0} p' docs/DESIGN.md
    echo; echo "## 5. YOUR CHAPTERS"
    for n in $CH; do awk -v n="$n" '$0 ~ "^"n"\\. \\*\\*" {p=1;print;next} /^[0-9]+\. \*\*/ || /^## /{p=0} p' docs/CHAPTERS.md; done
    echo; echo "## 6. ARCHITECTURE (contracts)"
    awk '/^## (Chapter contract|Interactable contract|Dialogue JSON|Autoloads)/{p=1;print;next} /^## /{p=0} p' docs/ARCHITECTURE.md
  fi
  echo; echo "## 7. TASKS"; cat docs/TASKS.md
  echo; echo "## 8. YOUR CHECKPOINT (docs/state/$ROLE.md)"; cat "docs/state/$ROLE.md" 2>/dev/null || cat docs/state/_TEMPLATE.md
  echo; echo "## 9. FILES YOU OWN (current listing, line counts)"
  for d in $DIRS; do [ -e $d ] && find $d -type f ! -name .gitkeep ! -name '*.import' 2>/dev/null; done | sort | while read f; do echo "$f ($(wc -l < "$f") lines)"; done
  echo; echo "## 10. FILES IN FLIGHT (full contents)"
  awk '/^## FILES IN FLIGHT/{p=1;next} /^## /{p=0} p && /^- /{sub(/^- /,"");sub(/ - .*/,"");print}' "docs/state/$ROLE.md" 2>/dev/null | while read f; do
    if [ -f "$f" ]; then echo; echo "### $f"; echo '```'; head -400 "$f"; echo '```'; fi
  done
} > "$OUT"
echo "Wrote $OUT ($(wc -c < "$OUT") bytes, ~$(( $(wc -c < "$OUT") / 4 )) tokens)"
echo "Attach it to a new chat and say: 'You are the $ROLE agent. Continue.'"
