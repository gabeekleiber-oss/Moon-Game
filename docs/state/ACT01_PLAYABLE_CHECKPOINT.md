# Act 1 playable blockout checkpoint (October 26, 2026)

Status: implementation complete for a first end-to-end interaction-driven blockout; awaiting a human real-window playthrough before claiming the act is finished.

- All 12 canonical Act 1 beat IDs are driven by spatial E interactions, in story order. Broom requires a real CarryController pickup; two TV strikes require holding the broom.
- Added the Wisconsin living-room intruder/letter/TV route, entry and kitchen actions, stair portals to Mary Sue's relocated non-overlapping bedroom, telephone/tank interactions, snowy driveway and Taurus departure interaction.
- After family boarding, the headlights cue appears; interacting with the Taurus again transitions to Act 2. No debug N shortcut required.
- Atmosphere: TV glow extinguishes on the first hit; impossible sun shines over the winter-night driveway.
- New `tests/test_act01_playthrough.tscn` and `tests/test_act01_transition.tscn` runs all 12 beats and asserts Act 2 unlocks. Headless tests passed, including room separation, stair portals, a real first-person interaction ray finding the intruder, and Taurus transition into Act 2.
- Important limitations: objects and characters are low-poly placeholders, the phone and tank are staged interaction sequences rather than simulated throws, stairs are temporary room portals, no full human real-window playthrough yet. Do not mark A-01 DONE until these are reviewed.
- Entry point: `builds/windows/MoonGame.exe` after re-export; Godot scene `scenes/acts/act01_wisconsin/act01_wisconsin.tscn`.
