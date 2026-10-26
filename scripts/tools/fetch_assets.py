#!/usr/bin/env python3
"""Automatic asset fetcher: closes the asset request loop without a human downloading files.

  python3 scripts/tools/fetch_assets.py                 Act 1 requests only (default), then import
  python3 scripts/tools/fetch_assets.py --priority 1    every open Priority 1 request
  python3 scripts/tools/fetch_assets.py --all           every open automatable request
  python3 scripts/tools/fetch_assets.py --ids AR-006,AR-018
  python3 scripts/tools/fetch_assets.py --dry-run       show what it would pick, download nothing
  python3 scripts/tools/fetch_assets.py --pick AR-006=ambientcg:Snow006   force a choice (also: data/assets/picks.json)
  python3 scripts/tools/fetch_assets.py --res 1k        texture resolution (default 2k; models use 1k)

Sources (all CC0 unless noted): ambientCG and Poly Haven (materials, HDRIs, models), Google Fonts via GitHub (OFL).
It writes `assets/_inbox/AR-nnn_<name>.zip` plus an `AR-nnn.txt` sidecar (Author / Source URL / License), runs
`assets.py import`, and records every pick in docs/ASSET_PICKS.md so a human can review and override.
Network: needs api.polyhaven.com, dl.polyhaven.org, ambientcg.com, raw.githubusercontent.com.
If the sandbox blocks them it fails per request and changes nothing. Freesound audio (AR-032/033) needs an API key: not automated.
Picks are keyword matches, not art direction: the human should glance at docs/ASSET_PICKS.md and override bad ones."""
import argparse, datetime, hashlib, io, json, os, pathlib, re, shutil, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request, zipfile

ROOT = pathlib.Path(os.environ.get("MOON_ROOT") or pathlib.Path(__file__).resolve().parents[2])
DATA, INBOX, PICKS, REPORT = ROOT / "data/assets/requests.json", ROOT / "assets/_inbox", ROOT / "data/assets/picks.json", ROOT / "docs/ASSET_PICKS.md"
UA = "MoonGame-asset-fetch/1.0 (CC0 assets for a personal game project)"
PH, ACG, RAW = "https://api.polyhaven.com", "https://ambientcg.com/api/v2/full_json", "https://raw.githubusercontent.com/google/fonts/main/ofl/"
ACT1 = ["AR-002", "AR-003", "AR-004", "AR-005", "AR-006", "AR-015", "AR-018", "AR-019", "AR-020", "AR-021", "AR-023", "AR-031"]
FONT_FAMILIES = {"AR-031": ["ebgaramond", "courierprime", "reeniebeanie"]}  # serif book, typewriter, handwriting (all OFL)
ORDER = {"material": ["ambientcg", "polyhaven"], "texture": ["ambientcg", "polyhaven"], "hdri": ["polyhaven"], "model": ["polyhaven"]}
PH_TYPE = {"material": "textures", "texture": "textures", "hdri": "hdris", "model": "models"}
SYN = {"tv": ["television"], "television": ["tv"], "crt": ["television", "tv"], "couch": ["sofa"], "sofa": ["couch"], "recliner": ["armchair"], "armchair": ["chair"],
       "linoleum": ["tile", "vinyl"], "paneling": ["panel", "wood"], "plywood": ["wood"], "cupboard": ["cabinet"], "carpet": ["rug", "fabric"]}
STOP = {"the", "a", "an", "and", "or", "of", "for", "old", "retro", "worn", "aged", "floor", "wall", "road"}
MAX_FILE = 50 * 1024 * 1024
SAVED = []  # report rows


# ---------- network (patched in tests) ----------
def http_get(url, timeout=90):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def http_json(url):
    return json.loads(http_get(url).decode("utf-8"))


def fetch(url, dest, md5=None):
    data = http_get(url)
    if len(data) > MAX_FILE: raise ValueError("file over 50 MB, skipped: " + url)
    if md5 and hashlib.md5(data).hexdigest() != md5: raise ValueError("md5 mismatch: " + url)
    dest.parent.mkdir(parents=True, exist_ok=True); dest.write_bytes(data); time.sleep(0.15)


def safe_rel(p):
    p = p.replace("\\", "/").lstrip("/")
    if ".." in p.split("/"): raise ValueError("unsafe path: " + p)
    return p


# ---------- matching ----------
def tokens(seg):
    out = []
    for t in re.split(r"[^a-z0-9]+", seg.lower()):
        if t and t not in STOP and t not in out: out.append(t)
    return out


def score(toks, aid, a):
    name = (aid + " " + str(a.get("name", ""))).lower().replace("_", " ")
    tags = " ".join(map(str, list(a.get("tags", [])) + list(a.get("categories", [])))).lower()
    s = 0.0
    for t in toks:
        alts = [t] + SYN.get(t, [])
        if any(x in name for x in alts): s += 1
        elif any(x in tags for x in alts): s += 0.5
    return s + min(float(a.get("download_count", 0) or 0), 1e6) / 1e8


_ph_cache = {}


def ph_find(kind, seg):
    t = PH_TYPE[kind]
    if t not in _ph_cache: _ph_cache[t] = http_json("%s/assets?t=%s" % (PH, t))
    toks = tokens(seg); best = None
    for aid, a in _ph_cache[t].items():
        s = score(toks, aid, a if isinstance(a, dict) else {})
        if s >= 1 and (best is None or s > best[0]): best = (s, aid)
    return ("polyhaven", best[1], best[0]) if best else None


def acg_find(seg):
    toks = tokens(seg)
    for q in [" ".join(toks)] + sorted(toks, key=len, reverse=True):
        if not q: continue
        try:
            j = http_json(ACG + "?" + urllib.parse.urlencode({"q": q, "type": "Material", "sort": "Popular", "limit": "8", "include": "downloadData"}))
        except Exception:
            continue
        found = j.get("foundAssets") or []
        if found: return ("ambientcg", found[0]["assetId"], 1.0, found[0])
    return None


def find(kind, seg):
    for src in ORDER.get(kind, []):
        try:
            c = acg_find(seg) if src == "ambientcg" else ph_find(kind, seg)
        except Exception as e:
            print("   %s search failed: %s" % (src, e)); continue
        if c: return c
    return None


# ---------- downloads ----------
def pick_res(node, want):
    order = ["1k", "2k", "4k", "8k", "16k"]
    have = [r for r in order if r in node] or list(node)
    if want in have: return want
    lower = [r for r in have if r in order and order.index(r) < order.index(want)] if want in order else []
    return lower[-1] if lower else have[0]


def ph_author(aid):
    try:
        a = http_json("%s/info/%s" % (PH, aid)).get("authors") or {}
        return ", ".join(a) if a else "Poly Haven contributors"
    except Exception:
        return "Poly Haven contributors"


def ph_download(kind, aid, res, out):
    files = http_json("%s/files/%s" % (PH, aid)); n = 0
    if kind in ("material", "texture"):
        for key, label in (("Diffuse", "albedo"), ("nor_gl", "normal"), ("Rough", "roughness"), ("AO", "ao"), ("Metal", "metallic"), ("Displacement", "height")):
            node = files.get(key)
            if not isinstance(node, dict): continue
            r = pick_res(node, res); fm = next((f for f in ("jpg", "png") if f in node[r]), None) or next(iter(node[r]))
            info = node[r][fm]; fetch(info["url"], out / ("%s_%s_%s.%s" % (aid, label, r, fm)), info.get("md5")); n += 1
    elif kind == "hdri":
        node = files.get("hdri") or {}; r = pick_res(node, "1k"); fm = next((f for f in ("hdr", "exr") if f in node[r]), None) or next(iter(node[r]))
        info = node[r][fm]; fetch(info["url"], out / ("%s_%s.%s" % (aid, r, fm)), info.get("md5")); n = 1
    else:  # model: glTF plus its included textures and buffers
        node = (files.get("gltf") or {}); r = pick_res(node, "1k"); g = node[r]["gltf"]
        base = out / aid; fetch(g["url"], base / (aid + "_" + r + ".gltf"), g.get("md5")); n = 1
        for rel, info in (g.get("include") or {}).items():
            fetch(info["url"], base / safe_rel(rel), info.get("md5")); n += 1
    if not n: raise ValueError("no usable files for " + aid)
    return ph_author(aid), "https://polyhaven.com/a/" + aid


def acg_download(res, a, out):
    zips = (((a.get("downloadFolders") or {}).get("default") or {}).get("downloadFiletypeCategories") or {}).get("zip", {}).get("downloads") or []
    want = [res.upper() + "-JPG", "2K-JPG", "1K-JPG"]
    link = next((d["downloadLink"] for w in want for d in zips if d.get("attribute") == w), None) or (zips[0]["downloadLink"] if zips else None)
    if not link: raise ValueError("no zip download listed for " + a["assetId"])
    z = zipfile.ZipFile(io.BytesIO(http_get(link)))
    for m in z.namelist(): safe_rel(m)
    (out / a["assetId"]).mkdir(parents=True, exist_ok=True); z.extractall(out / a["assetId"]); time.sleep(0.15)
    return "ambientCG.com (CC0 asset library by Lennart Demes and contributors)", "https://ambientcg.com/view?id=" + a["assetId"]


def font_download(fam, out):
    """Reads METADATA.pb from raw.githubusercontent.com (no GitHub API, which rate-limits shared IPs)."""
    base = RAW + fam + "/"
    meta = http_get(base + "METADATA.pb").decode("utf-8", "replace")
    m = re.search(r'designer:\s*"([^"]+)"', meta); author = m.group(1) if m else fam
    lic = re.search(r'license:\s*"([^"]+)"', meta); lic = lic.group(1) if lic else "OFL"
    if lic != "OFL": raise ValueError("%s is licensed %s, not OFL; skipped" % (fam, lic))
    names = re.findall(r'filename:\s*"([^"]+\.ttf)"', meta)
    names = [n for n in names if "italic" not in n.lower()] or names
    if not names: raise ValueError("no ttf listed for " + fam)
    names.sort(key=lambda n: (("[" not in n) and ("regular" not in n.lower()), len(n)))
    for n in names[:2]: fetch(base + urllib.parse.quote(n), out / fam / n)
    try: fetch(base + "OFL.txt", out / fam / "OFL.txt")
    except Exception: pass
    return author, "https://fonts.google.com/specimen/" + re.sub(r"[^A-Za-z0-9]+", "+", re.search(r'name:\s*"([^"]+)"', meta).group(1) if re.search(r'name:\s*"([^"]+)"', meta) else fam), "SIL Open Font License 1.1 (OFL)"


# ---------- per request ----------
def slug(s): return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")[:40] or "asset"


def parse_pick(s):
    src, _, aid = s.partition(":")
    if src not in ("polyhaven", "ambientcg") or not aid: raise SystemExit("bad pick (use source:id): " + s)
    return src, aid


def handle(r, res, picks, dry):
    rid, kind = r["id"], r["kind"]
    print("%s  %s (%s)" % (rid, r["title"], kind))
    work = pathlib.Path(tempfile.mkdtemp(prefix=rid + "_")); notes, rows = [], []
    try:
        if kind == "font":
            for fam in FONT_FAMILIES.get(rid, []):
                print("   font", fam)
                if dry: rows.append((fam, "Google Fonts", "https://fonts.google.com/specimen/" + fam)); continue
                au, url, lic = font_download(fam, work); notes.append("Author: %s | Source URL: %s | %s" % (au, url, lic)); rows.append((fam, au, url))
            lic_line = "SIL Open Font License 1.1 (OFL), all families"
        elif kind in ORDER:
            segs = [s.strip() for s in r["search"].split(";") if s.strip()][: (1 if kind in ("material", "texture", "hdri") else 4)]
            forced = picks.get(rid)
            if forced: forced = [forced] if isinstance(forced, str) else forced
            for k, seg in enumerate(segs if not forced else forced):
                if forced:
                    src, aid = parse_pick(seg); c = (src, aid, 9.9, None)
                    if src == "ambientcg":
                        c = (src, aid, 9.9, (http_json(ACG + "?" + urllib.parse.urlencode({"id": aid, "include": "downloadData"})).get("foundAssets") or [None])[0])
                else:
                    c = find(kind, seg)
                if not c: print("   no match for '%s'" % seg); continue
                src, aid = c[0], c[1]; print("   pick %s:%s (score %.1f) for '%s'" % (src, aid, c[2], seg if not forced else "override"))
                if dry: rows.append((src + ":" + aid, src, "dry-run")); continue
                try:
                    if src == "ambientcg":
                        if c[3] is None: raise ValueError("ambientCG did not return " + aid)
                        au, url = acg_download(res, c[3], work)
                    else:
                        au, url = ph_download(kind, aid, res, work)
                except Exception as e:
                    print("   download failed:", e); continue
                notes.append("Author: %s | Source URL: %s | License: CC0 1.0 Universal (Public Domain)" % (au, url)); rows.append((src + ":" + aid, au, url))
            lic_line = "CC0 1.0 Universal (Public Domain), all items"
        else:
            print("   not automatable (kind %s); do it by hand per docs/ASSET_REQUESTS.md" % kind); return None
        if not rows or dry:
            if not rows: print("   UNMATCHED: search by hand: %s" % r["search"])
            return rows or None
        if not notes: return None
        INBOX.mkdir(parents=True, exist_ok=True)
        zp = INBOX / ("%s_%s.zip" % (rid, slug(r["title"])))
        with zipfile.ZipFile(zp, "w", zipfile.ZIP_DEFLATED) as z:
            for p in sorted(work.rglob("*")):
                if p.is_file(): z.write(p, p.relative_to(work).as_posix())
        (INBOX / (rid + ".txt")).write_text("License: %s\nPicked-by: scripts/tools/fetch_assets.py (search: %s); review in docs/ASSET_PICKS.md\n%s\n" % (lic_line, r["search"], "\n".join(notes)), encoding="utf-8")
        print("   saved", zp.name, "(%d items)" % len(rows)); return rows
    except Exception as e:
        print("   FAILED:", e); return None
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ids", default=""); ap.add_argument("--priority", type=int, default=0); ap.add_argument("--all", action="store_true")
    ap.add_argument("--res", default="2k"); ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--no-import", action="store_true")
    ap.add_argument("--pick", action="append", default=[])
    a = ap.parse_args()
    d = json.loads(DATA.read_text(encoding="utf-8")); open_ = [r for r in d["requests"] if r["status"] == "requested"]
    if a.ids: want = [r for r in open_ if r["id"] in a.ids.split(",")]
    elif a.all: want = open_
    elif a.priority: want = [r for r in open_ if r["priority"] == a.priority]
    else: want = [r for r in open_ if r["id"] in ACT1]
    picks = json.loads(PICKS.read_text(encoding="utf-8")) if PICKS.exists() else {}
    for p in a.pick:
        k, _, v = p.partition("="); cur = picks.get(k, []); cur = [cur] if isinstance(cur, str) else list(cur); cur.append(v); picks[k] = cur
    if not want: print("nothing to fetch (no matching open requests)"); return 0
    got = []
    for r in want:
        rows = handle(r, a.res.lower(), picks, a.dry_run)
        if rows and not a.dry_run: got.append((r, rows))
    if got and not a.no_import:
        subprocess.run([sys.executable, str(ROOT / "scripts/tools/assets.py"), "import"], cwd=ROOT, check=False)
    if got:
        head = "" if REPORT.exists() else "# ASSET PICKS (written by fetch_assets.py; review and override with data/assets/picks.json or --pick AR-nnn=source:id)\n\nPicks are keyword matches. Open each page, check it looks right for the game, and override bad ones.\n"
        with REPORT.open("a", encoding="utf-8") as fh:
            fh.write(head + "\n## %s\n" % datetime.date.today().isoformat())
            for r, rows in got:
                fh.write("- **%s %s**: %s\n" % (r["id"], r["title"], "; ".join("%s ([page](%s))" % (x[0], x[2]) for x in rows)))
    print("fetched %d of %d requests%s" % (len(got), len(want), " (dry run)" if a.dry_run else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
