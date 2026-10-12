#!/usr/bin/env python3
"""Usage: python3 scripts/tools/story_lines.py N [beat_id]   Prints act N's VERBATIM story lines with their ids and beats
(from data/story/story_map.json + docs/source/STORY.md). Use the ids (s044...) as `src` anchors in dialogue data; copy text exactly,
typos included. Lines that straddle acts print under both. Never edit STORY.md."""
import json, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
text = [l.strip() for l in (root / "docs/source/STORY.md").read_text(encoding="utf-8").splitlines() if l.strip()]
m = json.loads((root / "data/story/story_map.json").read_text(encoding="utf-8"))["lines"]
if len(sys.argv) < 2: sys.exit(__doc__)
act = int(sys.argv[1]); want = sys.argv[2] if len(sys.argv) > 2 else None
for e in m:
    if act == e["act"] or act in e.get("also_acts", []):
        if want and want not in e["beats"]: continue
        print("%s  [%s]  (%s)\n%s\n" % (e["id"], ",".join(e["beats"]), e["kind"], text[e["n"] - 1]))
