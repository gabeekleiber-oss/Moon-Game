#!/usr/bin/env bash
# Usage: bash scripts/tools/strip.sh [scene.tscn ...]     Renders each scene's camera and stitches the PNGs into /tmp/strip/strip.png (labelled).
# Default: the nine act scenes. Software GL, so this is a regression picture (did anything go black/empty?), not the final look.
cd "$(git rev-parse --show-toplevel)" || exit 1
if [ $# -eq 0 ]; then set -- $(ls scenes/acts/*/*.tscn); fi
rm -rf /tmp/strip; mkdir -p /tmp/strip; i=0; files=()
for s in "$@"; do
  case "$s" in res://*) r="$s" ;; *) r="res://${s#./}" ;; esac
  i=$((i+1)); png=$(printf "/tmp/strip/%02d_%s.png" "$i" "$(basename "$s" .tscn)")
  bash scripts/tools/shot.sh res://tests/_strip_shot.tscn -- --scene="$r" --out="$png" 2>&1 | grep -E '^FAIL|SCRIPT ERROR'
  [ -f "$png" ] && files+=("$png") || echo "FAIL no image for $s"
done
python3 - "${files[@]}" <<'PY'
import sys
from PIL import Image, ImageDraw
fs=sys.argv[1:]
if not fs: sys.exit("no images")
W=400; ims=[]
for f in fs:
    im=Image.open(f).convert("RGB"); im=im.resize((W,int(im.height*W/im.width)))
    ImageDraw.Draw(im).text((6,6),f.split("/")[-1][:-4],fill=(255,255,0)); ims.append(im)
cols=min(3,len(ims)); rows=(len(ims)+cols-1)//cols; H=ims[0].height
strip=Image.new("RGB",(W*cols,H*rows))
for k,im in enumerate(ims): strip.paste(im,((k%cols)*W,(k//cols)*H))
strip.save("/tmp/strip/strip.png"); print("strip:", "/tmp/strip/strip.png", len(ims), "images")
PY
