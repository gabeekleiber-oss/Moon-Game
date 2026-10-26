#!/usr/bin/env python3
"""Offline test of fetch_assets.py with a fake Poly Haven / ambientCG (API shapes as documented; real calls are not exercised here).
Run: python3 scripts/tools/test_fetch_assets.py"""
import importlib.util, io, json, os, pathlib, shutil, sys, tempfile, zipfile
HERE = pathlib.Path(__file__).resolve().parent
tmp = pathlib.Path(tempfile.mkdtemp()); shutil.copytree(HERE.parents[1] / "data", tmp / "data"); (tmp / "scripts/tools").mkdir(parents=True)
shutil.copy(HERE / "assets.py", tmp / "scripts/tools/assets.py"); (tmp / "assets/_inbox").mkdir(parents=True); (tmp / "docs").mkdir()
os.environ["MOON_ROOT"] = str(tmp)
spec = importlib.util.spec_from_file_location("fa", HERE / "fetch_assets.py"); fa = importlib.util.module_from_spec(spec); spec.loader.exec_module(fa)
fa.time.sleep = lambda *_: None
def acg_zip(): b = io.BytesIO(); z = zipfile.ZipFile(b, "w"); z.writestr("Carpet001_2K_Color.jpg", "x"); z.writestr("Carpet001_2K_NormalGL.jpg", "x"); z.close(); return b.getvalue()
PH_LIST = {"textures": {"snow_02": {"name": "Snow 02", "tags": ["snow", "ground"], "categories": ["terrain"], "download_count": 5}, "brick": {"name": "Brick", "tags": [], "categories": []}},
           "models": {"Television_01": {"name": "Television 01", "tags": ["tv", "retro", "crt"], "categories": ["electronics"]}, "Sofa_01": {"name": "Sofa 01", "tags": ["couch"], "categories": ["furniture"]},
                      "ArmChair_01": {"name": "Arm Chair 01", "tags": ["recliner"], "categories": ["furniture"]}, "Lantern": {"name": "Lantern", "tags": [], "categories": []}},
           "hdris": {"kloppenheim_02": {"name": "Kloppenheim 02", "tags": ["night", "sky"], "categories": ["night"]}}}
def files(aid):
    if aid == "snow_02": return {"Diffuse": {"1k": {"jpg": {"url": "u/d1", "md5": None}}, "2k": {"jpg": {"url": "u/d2"}}}, "nor_gl": {"2k": {"png": {"url": "u/n"}}}, "Rough": {"2k": {"jpg": {"url": "u/r"}}}}
    if aid == "kloppenheim_02": return {"hdri": {"1k": {"hdr": {"url": "u/h"}}, "4k": {"hdr": {"url": "u/h4"}}}}
    return {"gltf": {"1k": {"gltf": {"url": "u/m.gltf", "include": {"textures/diff.jpg": {"url": "u/t"}, "m.bin": {"url": "u/b"}}}}}}
def acg_json(url):
    return {"foundAssets": [{"assetId": "Carpet001", "downloadFolders": {"default": {"downloadFiletypeCategories": {"zip": {"downloads": [{"attribute": "2K-JPG", "downloadLink": "https://ambientcg.com/get?file=Carpet001_2K-JPG.zip"}]}}}}}]}
def jget(url):
    if url.startswith(fa.ACG): return acg_json(url) if "carpet" in url.lower() or "linoleum" in url.lower() or "wood" in url.lower() else {"foundAssets": []}
    if "/assets?t=" in url: return PH_LIST[url.split("t=")[1]]
    if "/files/" in url: return files(url.rsplit("/", 1)[1])
    if "/info/" in url: return {"authors": {"Rob Tuytel": "All"}}
    raise AssertionError(url)
def bget(url, timeout=0): return acg_zip() if "ambientcg.com/get" in url else b"data:" + url.encode()
fa.http_json, fa.http_get = jget, bget
fail = 0
def check(c, m):
    global fail
    if not c: fail += 1; print("FAIL:", m)
sys.argv = ["fa", "--ids", "AR-002,AR-006,AR-018,AR-019,AR-015,AR-022", "--no-import"]
fa.main()
names = sorted(p.name for p in (tmp / "assets/_inbox").iterdir())
check(any(n.startswith("AR-002") and n.endswith(".zip") for n in names), "carpet zip from ambientCG: %s" % names)
check(any(n.startswith("AR-006") for n in names), "snow zip from Poly Haven fallback")
check(any(n.startswith("AR-018") for n in names), "tv model zip")
z = zipfile.ZipFile(next(p for p in (tmp / "assets/_inbox").glob("AR-019*.zip"))); zn = z.namelist()
check(any("Sofa_01" in n for n in zn) and any("ArmChair_01" in n for n in zn), "sofa and recliner both fetched: %s" % zn)
check(any(n.endswith("textures/diff.jpg") for n in zipfile.ZipFile(next((tmp / "assets/_inbox").glob("AR-018*.zip"))).namelist()), "gltf includes kept")
check(any("snow_02_albedo_2k.jpg" in n for n in zipfile.ZipFile(next((tmp / "assets/_inbox").glob("AR-006*.zip"))).namelist()), "texture naming and 2k pick")
check(any("kloppenheim_02_1k.hdr" in n for n in zipfile.ZipFile(next((tmp / "assets/_inbox").glob("AR-015*.zip"))).namelist()), "hdri 1k")
check(not any(n.startswith("AR-022") for n in names), "unmatched sedan should produce no file")
side = (tmp / "assets/_inbox/AR-006.txt").read_text(); check("License: CC0" in side and "https://polyhaven.com/a/snow_02" in side and "Rob Tuytel" in side, "sidecar fields: " + side)
# import + verify through the real assets.py
import subprocess
r = subprocess.run([sys.executable, str(tmp / "scripts/tools/assets.py"), "import"], cwd=tmp, capture_output=True, text=True); check("imported AR-006" in r.stdout, "import: " + r.stdout + r.stderr)
r = subprocess.run([sys.executable, str(tmp / "scripts/tools/assets.py"), "verify"], cwd=tmp, capture_output=True, text=True); check(r.returncode == 0, "verify: " + r.stdout)
# unsafe path rejected
try: fa.safe_rel("../x"); check(False, "unsafe path accepted")
except ValueError: pass
shutil.rmtree(tmp, ignore_errors=True)
print("fetch_assets offline test:", "PASS" if not fail else "%d FAILED" % fail); sys.exit(1 if fail else 0)
