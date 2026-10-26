# Act 1 playable blockout checkpoint (October 26, 2026)

Status: implementation complete for a first end-to-end interaction-driven blockout; awaiting a human real-window playthrough before claiming the act is finished.

- All 12 canonical Act 1 beat IDs are driven by spatial E interactions, in story order. Broom requires a real CarryController pickup; two TV strikes require holding the broom.
- Added the Wisconsin living-room intruder/letter/TV route, entry and kitchen actions, stair portals to Mary Sue's relocated non-overlapping bedroom, telephone/tank interactions, snowy driveway and Taurus departure interaction.
- After family boarding, the headlights cue appears; interacting with the Taurus again transitions to Act 2. No debug N shortcut required.
- Atmosphere: TV glow extinguishes on the first hit; impossible sun shines over the winter-night driveway.
- New `tests/test_act01_playthrough.tscn` and `tests/test_act01_transition.tscn` runs all 12 beats and asserts Act 2 unlocks. Headless tests passed, including room separation, stair portals, a real first-person interaction ray finding the intruder, and Taurus transition into Act 2.
- Important limitations: objects and characters are low-poly placeholders, the phone and tank are staged interaction sequences rather than simulated throws, stairs are temporary room portals, no full human real-window playthrough yet. Do not mark A-01 DONE until these are reviewed.
- Entry point: `builds/windows/MoonGame.exe` after re-export; Godot scene `scenes/acts/act01_wisconsin/act01_wisconsin.tscn`.
## October 26 export hotfix after first player report
- Initial Windows build showed five stub pillars because standalone export did not preserve `room_ids` PackedStringArray scene override. Fixed by assigning Act 1 room IDs explicitly at runtime; exported binary now constructs five interior room meshes and no debug pillars.
- Added JSON export include filters for world, story, dialogue, audio resources.
- First-run settings auto-open paused standalone gameplay; removed automatic pause on startup (settings remain available from Esc). Setup panel is opt-in with `--setup`.
- Spawn moved inside living room rather than on its boundary.
- Added `--verify-export` main-scene diagnostic, exercised against the **actual exported EXE**. Result: room construction PASS; player unlocked/unpaused PASS; simulated W movement 1.73m PASS. Windows forward and compatibility renderer smoke PASS. Act 1 end-to-end tests PASS.
- Human mouse-look and real-window navigation still need player confirmation.
## First-person camera/visibility hotfix after user screenshot
- Root cause: autoload `CutsceneCamera` was the active viewport camera, so movement did not visibly change the picture; the image showed geometry from the wrong vantage point.
- Explicit `Player/Head/Camera3D.make_current()` when player spawns; lowered Act 1 player spawn from 1.0m to 0.1m so the camera is below the 2.4m ceiling; hid the local player body mesh from first person.
- Confirmed via **actual rendered Windows executable screenshot**: correct living room and objects now visible, not black/off-angle cutscene view. Screenshot at `user://act1_visual.png` (debug `--capture-act1`).
- Improved placeholder hands placement, removed duplicated on-screen objective message.
- `--verify-export` now checks camera ownership, camera height, 1.7m actual forward movement, and mouse-look math; all PASS in exported EXE. Full Godot suite 41/41 PASS; both renderer smokes PASS.
- Human mouse input and full act playthrough remain to be confirmed; screenshots are visual blockouts, not final art.
