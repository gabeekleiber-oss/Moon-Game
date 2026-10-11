#!/usr/bin/env bash
# Task queue helper. Usage: tasks.sh next | status ID | line ID | field ID needs|ch | set ID STATUS
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; F="$ROOT/docs/TASKS.md"
cmd="$1"; id="$2"
case "$cmd" in
  status) awk -v id="$id" '/^- \(/{gsub(/\r/,""); split($0,a,"[()]"); if(a[2]==id){n=split($0,p," \\| "); print p[n]; exit}}' "$F";;
  line)   grep "^- ($id) " "$F" | tr -d '\r';;
  field)  awk -v id="$id" -v key="$3" '/^- \(/{gsub(/\r/,""); split($0,a,"[()]"); if(a[2]==id){n=split($0,p," \\| "); for(i=1;i<=n;i++) if(index(p[i],key": ")==1){print substr(p[i],length(key)+3)}; exit}}' "$F";;
  set)    sed -i.bak "/^- ($id) /s/ | [A-Z-]*\r\{0,1\}$/ | $3/" "$F" && rm -f "$F.bak";;
  next)   awk '
    FNR==NR{ if($0 ~ /^- \(/){ gsub(/\r/,""); split($0,a,"[()]"); n=split($0,p," \\| "); st[a[2]]=p[n]} next }
    /^- \(/{ gsub(/\r/,""); split($0,a,"[()]"); n=split($0,p," \\| "); if(p[n]!="TODO") next; ok=1
      for(i=1;i<=n;i++) if(index(p[i],"needs: ")==1){ s=substr(p[i],8); m=split(s,d,","); for(j=1;j<=m;j++){ gsub(/ /,"",d[j]); if(d[j]!="-" && d[j]!="" && st[d[j]]!="DONE") ok=0 } }
      if(ok){print a[2]; exit} }' "$F" "$F";;
  *) echo "Usage: tasks.sh next|status ID|line ID|field ID needs|ch|set ID STATUS"; exit 1;;
esac
