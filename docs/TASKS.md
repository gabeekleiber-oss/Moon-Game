# TASKS (shared queue - edited ONLY by scripts/tools, never by agents)
Line format: `- (ID) description | needs: IDs or - | ch: acts or - | STATUS`   STATUS = TODO / IN-PROGRESS / DONE   (`ch` = the act numbers whose story text and beats the task needs)
`make_context.sh` / `start.sh` claim the next TODO task whose `needs` are all DONE. A task can be bigger than one chat: it is finished in many small steps.
Direction: an explorable, realistic, unnerving experience game (docs/VISION.md). The world, the map and the art are the work; there is no score, health or HUD.

## Systems (build first; many can run in parallel)
- (S-01) Look and lighting baseline: Forward+ project settings, WorldEnvironment preset library (night-dark, dawn, dream, day, fire) with SSAO/glow/fog/tonemap, volumetric light shafts, LightmapGI/probe baking workflow, light helpers (practical lamp, window light, candle, TV flicker, moon), a lighting test room, written budgets (ART_BIBLE 4) | needs: - | ch: - | DONE
- (S-02) Asset pipeline and materials: `assets/LICENSES.md` + checker, AssetCatalog with code-built fallbacks, PBR material loader, decal helpers, a library of Unreality surface shaders (damp, rot, swim, crawl) using the global `unreality` uniforms, `scripts/tools/import_assets.sh` so the human can drop CC0 packs in | needs: - | ch: - | IN-PROGRESS
- (S-03) Player and carry: movement feel, crouch/duck under low chandeliers, subtle head bob, footsteps by surface, stair handling, first-person hands/forearms, and a CARRY system (pick up and hold Mary Sue, the pot, the axe, the broom) with weight and sway | needs: - | ch: - | TODO
- (S-04) Narration and text presenter: on-screen narration/dialogue (verse typeset as verse, speech with voice-blips), Unreality text effects (words swim, a line repeats, a word is replaced, "I" slips to "he"), Reduced Motion fallbacks, always-on subtitles | needs: - | ch: - | TODO
- (S-05) World data and RoomBuilder: `data/world/*.json` spec from WORLD_BIBLE, a generator for walls/floors/ceilings/doors/windows/trim with collision and navigation, door locks tied to beat ids, tests (footprints do not overlap, doors align, every route in the door graph connects) | needs: S-02 | ch: - | TODO
- (S-06) Mansion blockout: the whole Gronfiser house + exterior as correct-scale greybox from the plan, every story route walkable (including the kitchen back stair and the enfilade), dome tower with glass dome, room markers, a route-walker test | needs: S-05 | ch: 3,4,7,8,9 | TODO
- (S-07) WrongnessDirector: registry of objects with `wrong_id` plus a behaviour library (lean, swap, drift, move-when-unseen, door-destination change, corridor stretch, eyes follow, count wrong, light misbehaves), an "observed" check, deterministic order via `Unreality.wrongs`, tests | needs: S-05 | ch: - | TODO
- (S-08) Character pipeline: realistic bodies/faces from CC0 bases with morphs (age, relative, wrongness), hair, eye shader, clothing, voice-blip hookup, LODs, the "unfinished face" fallback; Elsa Ray, Mary Sue, Frank, the Sweaty Man, Clement, Edith silhouette, Joshua Primo statue base | needs: S-02 | ch: - | TODO
- (S-09) Audio design layer: per-space ambience (room tone, wind, cicadas, grackles, house settling), per-room reverb zones, occlusion, Unreality audio (detuning music-box, dropouts, whispers, doubled voices), integration with the existing MusicSequencer | needs: - | ch: - | DONE
- (S-10) Moon and Eye upgrade: displaced cratered moon material, wet iris/sclera/cornea shader (green and blue), moon-skin lids, reacts to Unreality, dome-view and window-view variants (builds on the existing code-made MoonEye) | needs: S-02 | ch: 3 | TODO
- (S-11) Title, start and save: title with the moon, Begin/Continue, save/load progress (act, flags, Unreality), credits stub | needs: S-10 | ch: - | TODO
- (S-12) Performance, smoke and visual regression: frame-time probe scenes, a headless smoke test that loads every act and room, screenshot-strip tool, `scripts/tools/perf.sh`, budget tests (draw calls, lights) | needs: - | ch: - | TODO
- (S-13) Vehicle and driving: the 1994 Ford Taurus (interior and exterior), driving controller with hills and air, headlight rig, road-segment generator hooks | needs: S-02 | ch: 1,2,3 | TODO
- (S-14) Fire, smoke and atmosphere VFX: fire, embers, melting-metal glow, dust motes and light shafts, cobwebs, snow, breath fog, with strict particle budgets and Reduced Motion variants | needs: - | ch: 9 | TODO
- (S-15) Physical verbs: forgiving contextual actions with physics and sound (kick, throw phone/tank, swing the broom, chop with the axe, roll the pot, strike a match, cut the cake), no meters | needs: S-03 | ch: 1,2,6,9 | TODO
- (S-16) Birds: realistic birds and nests, twelve species, a flock (boids; the v1 version is at `git show v1-gamified:scenes/birds/boids.gd`), the twelve-arm nest lantern, the kite, perch/speak/follow behaviours | needs: S-02 | ch: 4,5 | TODO
- (S-17) Windows packaging: Windows 10 export preset (64-bit, embedded PCK), `scripts/tools/export_windows.sh`, min-spec quality presets (Forward+ high/medium, Compatibility fallback), launch options, a first-run settings check | needs: S-01 | ch: - | TODO

## Locations (world-building: the top priority; each starts with a dressing checklist, WORLD_BIBLE)
- (L-01) The Wisconsin house: living room (27-inch RCA CRT, couch, 1990s detail), kitchen, hall closet, Mary Sue's room with the fish tank, snowy yard and driveway | needs: S-05,S-01 | ch: 1 | TODO
- (L-02) The night road: road-segment set-pieces (the fork, the inn, the long straight, hills, the racoon and trashcan), forest-wall corridor, dawn transition | needs: S-13,S-01 | ch: 2 | TODO
- (L-03) The clearing and mansion exterior: facade of oak and red brick, windows, chimneys, glass dome on the roof, porch, winding dirt path, forest ring, shed, woodpile, slope | needs: S-01,S-02 | ch: 3,9 | TODO
- (L-04) Mansion ground floor: Foyer, Stair Hall with grand stair, Bird Hall (dirt floor), Dining Room (twenty-seat table), Kitchen, west service rooms | needs: S-06 | ch: 3,4,7,8,9 | TODO
- (L-05) Mansion upper floor: balcony gallery, Portrait Hall and foyer bridge, master bedroom (seven pillows), kids' rooms, closet suite, the dome room | needs: S-06 | ch: 3,4,7,9 | TODO
- (L-06) The enfilade and the east wing: Military Gallery (armour), Bird Statue Room, Gold Statue Room (statues), decayed East Wing with the melting pot | needs: S-06 | ch: 8,9 | TODO
- (L-07) Dream spaces: the maroon hall of identical doors, the exact Wisconsin-kitchen replica, the narrowing hall that becomes forest | needs: L-01,S-06 | ch: 5 | TODO
- (L-08) The lake: forest path, clearing, glassy lake that never meets the sky, canoe, reeds, bobber, Clement's seat | needs: S-01,S-02 | ch: 6 | TODO
- (L-09) The fire clearing: stump, woodpile, slope, the fire pit, lawn, melt VFX staging | needs: L-03,S-14 | ch: 9 | TODO

## Acts (story scripting: beats, interactions, dialogue data from the verbatim text, cues, wrongness, shocks)
- (A-01) Act 1 The Fourteenth of September: intruder, finger shock, letter, shoo, kitchen items, broom, TV twice, quit, phone and tank, the loaded Taurus | needs: L-01,S-03,S-04,S-08,S-15 | ch: 1 | TODO
- (A-02) Act 2 The Road South: leave, night road, warning verse, the inn, stay left, racoon, the road "game", Elsa's buzzing voice, dawn | needs: L-02,S-13,S-04,S-09 | ch: 2 | TODO
- (A-03) Act 3 The Moon With an Eye: arrival, locked doors, dome, the eye speaks, the argument, the eye vanishes, house goes dark | needs: L-03,L-04,L-05,S-10,S-04 | ch: 3 | TODO
- (A-04) Act 4 The First Night of Rooms: stumble in the dark, switch, the bird lantern, Mary Sue, "leave the girl", the left-right-left run, the closet, cyclone | needs: L-04,L-05,S-03,S-07,S-09,S-16 | ch: 4 | TODO
- (A-05) Act 5 Thirteen Candles: the maroon hall, the kitchen replica, cake and song, the faces change, Frank and Clement, forest | needs: L-07,S-08,S-16,S-04 | ch: 5 | TODO
- (A-06) Act 6 The Lake: forest path, Frank's argument, the canoe, the speech, the memory, the bobber and bass, "Hello, son." | needs: L-08,S-08,S-04,S-15 | ch: 6 | TODO
- (A-07) Act 7 Morning at the Gronfiser's: wake, seven pillows, the portraits, the stairs, breakfast, the Gronfiser verse, "I left. When they both died." | needs: L-04,L-05,S-08,S-04 | ch: 7 | TODO
- (A-08) Act 8 The Inventory: the notepad, the enfilade of armour, birds and gold, the fleas begin | needs: L-04,L-06,S-04,S-07 | ch: 8 | TODO
- (A-09) Act 9 The Melting Spree: the plan, the bags, Elsa's confrontation, axe and logs, the pot, the fall, the fire, the flute dance, bed, the eye | needs: L-03,L-04,L-05,L-06,L-09,S-14,S-15,S-08,S-07 | ch: 9 | TODO

## Final
- (Z-01) Integration pass: play start to finish, fix act transitions and cues, Unreality continuity, no console errors, route-walker green | needs: A-09 | ch: - | TODO
- (Z-02) Polish: lighting passes, shock timing, audio mix, accessibility, performance and adaptive quality | needs: Z-01 | ch: - | TODO

## Needs the human (not claimable)
- **Play regularly in a real window** and report what looks wrong (software screenshots cannot judge this quality).
- **Art references:** a few films, paintings or photographs you want the look to follow (drop in `docs/source/refs/`).
- **Asset packs:** download CC0 PBR packs/models (Poly Haven, ambientCG, Quaternius) into `assets/` (use `scripts/tools/import_assets.sh` once S-02 lands) or widen the sandbox network allowlist.
- **Enable CI:** move `docs/ci/tests.yml` to `.github/workflows/tests.yml` (needs a token with `workflow` scope or the web UI).
- **Approve** any new shock moment or any change to docs/ACTS.md and docs/WORLD_BIBLE.md that alters the story's physical layout.
