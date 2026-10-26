# ASSETS: the request loop (agents ask, the human downloads, agents use)
Agents cannot download from most sites (sandbox network allowlist) and cannot judge art in a real window. So assets move through a shared wishlist:
* **Wishlist:** `data/assets/requests.json` (33 seeded requests: materials, models, HDRIs, characters, fonts, audio; Priority 1 = Act 1 / vertical slice).
* **Human checklist:** `docs/ASSET_REQUESTS.md` (generated). The human downloads, renames to `AR-nnn_name.ext`, drops into `assets/_inbox/`, pushes (`assets/_inbox/README.md`).
* **Tool:** `python3 scripts/tools/assets.py list|add|checklist|import|verify`.
## Rules for agents
1. **Need something not in the repo? Do not invent it and do not wait.** Run `assets.py add "title" --kind ... --need "exact spec" --why "where used" --used-by ... --priority N`, then build a code-made `# PLACEHOLDER` fallback so the scene runs (the `AssetCatalog` task S-02 formalises this).
2. **Start of every session:** if `assets/_inbox/` has files, run `python3 scripts/tools/assets.py import` and commit. Then `assets.py list received` shows what you can now use; the target path is in the request.
3. **Using an asset:** load from its `target` folder; keep the fallback until the file exists (`ResourceLoader.exists`). Never copy an asset out of the inbox by hand (licenses would go unrecorded).
4. **Licenses:** CC0 first; CC-BY allowed with the credit line (assets.py records it); no unlicensed or "free for personal use" assets; no real-person likenesses (VISION).
5. Large files: keep textures <= 2K, models as `.glb`, audio `.ogg`; one file under ~50 MB (plain git, no LFS, so cloud agents get real files).
6. Source links are starting points (site homepages), never exact pages: search the request's terms on the site. Do not paste invented URLs.

## Automatic fetching (no human download needed)
`python3 scripts/tools/fetch_assets.py` finds and downloads CC0 assets for open requests (ambientCG and Poly Haven materials, HDRIs and models; Google Fonts via raw GitHub), writes the `AR-nnn` zip and license sidecar into `assets/_inbox/`, runs `assets.py import`, and logs each pick in `docs/ASSET_PICKS.md`. Default scope is the Act 1 set; see `--help` for `--priority`, `--all`, `--ids`, `--dry-run`, `--res`.
* **Where it can run:** (1) a GitHub Actions run: move `docs/ci/fetch_assets.yml` to `.github/workflows/` once, then Actions -> fetch-assets -> Run workflow (open internet, nothing to install). (2) Any agent or machine whose network allows `api.polyhaven.com`, `dl.polyhaven.org`, `ambientcg.com`, `raw.githubusercontent.com` (widen the Claude Code sandbox allowlist with those). (3) Your PC with Python 3 (`winget install Python.Python.3.12`).
* **Picks are keyword matches, not art direction.** Review `docs/ASSET_PICKS.md`; override with `--pick AR-006=ambientcg:Snow006` or `data/assets/picks.json` (`{"AR-006": ["ambientcg:Snow006"]}`). The next run replaces nothing already imported, so delete the bad request's files and set its status back to `requested` in `data/assets/requests.json` first.
* **Not automated:** AR-032/033 audio (Freesound needs an API key), AR-030 characters, and cars such as the Taurus (AR-022): those stay manual or use code-built fallbacks.
* Test (offline, mocked APIs): `python3 scripts/tools/test_fetch_assets.py`.
