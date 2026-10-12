#!/usr/bin/env bash
# Usage: bash scripts/tools/story_act.sh N      Prints act N's VERBATIM text from docs/source/STORY.md (the file itself is never edited).
# Act boundaries are the first occurrence of each anchor phrase in docs/source/ACT_ANCHORS.txt (format: N|phrase). Output is read-only reference:
# copy dialogue into data/ files exactly, including the original typos; never "fix" or invent story text.
cd "$(git rev-parse --show-toplevel)" || exit 1
N="$1"; [ -n "$N" ] || { echo "usage: story_act.sh N"; exit 1; }
S="$(awk -F'|' -v n="$N" '$1==n{print $2}' docs/source/ACT_ANCHORS.txt)"
E="$(awk -F'|' -v n="$((N+1))" '$1==n{print $2}' docs/source/ACT_ANCHORS.txt)"
[ -n "$S" ] || { echo "no anchor for act $N"; exit 1; }
tr -d '\r' < docs/source/STORY.md | awk -v s="$S" -v e="$E" '
  { line = $0 }
  !on { i = index(line, s); if (i == 0) next; on = 1; if (i > 4) line = substr(line, i) }
  on { if (e != "") { j = index(line, e); if (j > 0) { if (j > 4) print substr(line, 1, j - 1); exit } } print line }'
