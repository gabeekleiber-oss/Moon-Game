# Asset download pack: first pass

This is the shortest useful download list for dressing the first representative rooms. The complete generated inventory remains docs/ASSET_REQUESTS.md and data/assets/requests.json; use those as the source of truth for request IDs, target folders, and acceptance details.

## Download first: Act 1 + mansion materials
Choose one good CC0 asset per request, not multiple competing packs. Prefer 1K–2K tileable PBR materials with albedo/base color, normal, and roughness maps. Download the source archive or texture set in its original form.

| Request | What to search for | Why it matters |
|---|---|---|
| AR-001 | Worn black/white or cream/grey checker marble | Foyer and replica kitchen; establishes the mansion's first material signature |
| AR-002 | Worn beige low-pile 1990s carpet | Wisconsin house |
| AR-003 | Dark late-20th-century wood wall paneling | Wisconsin living room |
| AR-004 | Mid-brown stained kitchen cabinet veneer | Wisconsin and dream kitchen |
| AR-005 | Yellow-beige kitchen tile or linoleum | Wisconsin kitchen |
| AR-006 | Packed snow with subtle footprints/ice | Wisconsin yard |
| AR-007 | Worn asphalt with faded road markings | Night road |
| AR-009 | Aged dark red/oxblood brick | Mansion exterior |
| AR-010 | Dark oak planks and beams | Foyer, dining room, gallery |
| AR-012 | Aged cream plaster wall | Foyer and stair hall |

## Download next: hero props and readable silhouettes
Use the existing requests rather than substituting unrelated models:
- AR-018 — 1990s CRT television with a separate screen material.
- AR-019 — three-seat sofa and recliner.
- AR-021 — plain push broom.
- AR-022 — late-1980s/1990s family sedan; exact Ford Taurus is optional if the silhouette and interior work.
- AR-024 — ornate chandelier set.
- AR-027 — varied oak/pine/winter trees and undergrowth.
- AR-030 — rigged adult/child base meshes, only if a quality review approves them.
- AR-031 — readable serif, typewriter/monospace, and handwriting fonts with SIL Open Font License (OFL).

## Where to search
- [Poly Haven](https://polyhaven.com) — CC0 materials, models, and HDRIs.
- [ambientCG](https://ambientcg.com) — CC0 PBR materials and environment assets.
- [Quaternius](https://quaternius.com) — CC0 model packs; inspect the pack license and contents.
- [Sketchfab](https://sketchfab.com) — use explicit downloadable CC0 or CC-BY filters and retain the asset page URL.
- [Google Fonts](https://fonts.google.com) — verify the selected font is OFL before adding it.
- [MakeHuman Community](https://www.makehumancommunity.org) — possible base meshes; verify the exact exported asset's license.
These are search starting points, not guarantees that a particular asset exists or has the required license. Verify the license on the exact download page before use.

## How to hand downloads to the project
1. Download only a request that exists in docs/ASSET_REQUESTS.md; if absent, have an agent add it using python scripts/tools/assets.py add ...
2. Rename the downloaded archive/file so it starts with the request ID, for example AR-001_marble_checker.zip.
3. Put it in assets/_inbox/. Do not place it directly in a final asset folder.
4. Add assets/_inbox/AR-001.txt containing the exact source page URL, creator, license name, and attribution text (for CC-BY).
5. Commit/push the inbox asset(s). The next agent runs python scripts/tools/assets.py import and python scripts/tools/assets.py verify, then checks the generated license manifest and the asset's in-game appearance.
6. Keep any code-built placeholder until the imported asset is confirmed working in the target scene.

## Asset guardrails
- CC0 first; CC-BY only when its exact credit can be retained.
- No unclear, personal-use-only, pirated, scraped, or unlicensed assets.
- No real-person likenesses. Child character assets need extra review and should be generic licensed base meshes only.
- Keep ordinary textures at 2K or below unless a specific hero close-up has a measured need.
- Prefer .glb for 3D models and .ogg for audio. Keep individual Git-tracked files under roughly 50 MB; do not introduce Git LFS without approval.
