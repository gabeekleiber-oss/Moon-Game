# assets/_inbox: drop zone for downloaded assets
1. Open `docs/ASSET_REQUESTS.md` (the checklist of what the agents need).
2. Download a file, rename it to START WITH the request id: `AR-007_oak_floor.zip`, `AR-025_broom.glb`.
3. Put it here (zips are fine; one request can have several files, e.g. `AR-007_a.zip`, `AR-007_b.zip`).
4. Optional: `AR-007.txt` next to it with the author name and the page URL (this is recorded as the license source).
5. `git add assets && git commit -m "assets" && git push`. The next agent runs `python3 scripts/tools/assets.py import`, which files everything into the right folder, adds the license line to `assets/LICENSES.md`, and marks the request received.
Files not starting with `AR-nnn` are ignored. Only CC0 / CC-BY / OFL (fonts) / public domain; if unsure of the license, say so in the .txt.
