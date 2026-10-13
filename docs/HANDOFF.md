# HANDOFF (newest first). Written by scripts from finished tasks' HANDOFF NOTEs. Do not edit by hand.


<!-- done:S-12 -->
## S-12 done (2026-10-13)
- `SceneStats.collect(root)` / `violations(stats)` (scripts/perf/scene_stats.gd): lights, shadow lights, mesh surfaces, particles; scene-wide LIMITS are placeholders.
- `tests/test_smoke_scenes`: auto-scans every .tscn under res://scenes (new rooms/acts are covered with no edits), enters each for 2 frames, checks SceneStats. main.tscn is load-only.
- `bash scripts/tools/perf.sh [scene...]`: windowed probe (scenes/perf/frame_probe), JSON in /tmp/perf, fails on draw calls, scene limits or per-view LightBudget. Frame ms is meaningless under xvfb/llvmpipe; unverified on a real GPU.
- `bash scripts/tools/strip.sh [scene...]`: labelled PNG strip of scene cameras at /tmp/strip/strip.png (software GL, regression picture only).
- Gotcha: scenes with no Camera3D get a default camera at (0,1.6,4); the probe only checks per-view lights when the viewport has a camera.

<!-- done:S-01 -->
## S-01 done (2026-10-13)
- `scenes/lighting/env_presets.gd` (`EnvPresets`) owns the five looks and pure helpers for easing, Unreality, quality, and applying settings. `scenes/lighting/mood_environment.gd` (`MoodEnvironment`) is a `WorldEnvironment`; set `follow_grade = true` to follow the active PostFX base grade, or call `set_look(name, seconds)` for a mid-act change.
- Act 1 now includes one `MoodEnvironment` node with `follow_grade = true`. The global renderer defaults are in `project.godot`; the Windows test runner waits for the editor class scan before launching test scenes.
- `LightBudget.in_view(camera, root)` reports visible light and shadow counts. `BakeHelper.add_room_probes`, `ensure_uv2`, `mark_dynamic`, `mark_static`, and `set_light_baked` prepare rooms for editor baking. Bake outputs are not committed; bake each finished room in the Godot editor using `docs/LIGHTING.md`.
- Verification: `bash scripts/tools/run_tests.sh` passed on GitHub Actions (29 passed, 0 failed); the Windows `scripts/tools/run_tests.ps1` full suite also passed after the class-registration fixes.
- Remaining manual sign-off: inspect all five looks and volumetric shafts in a real Godot window; decide whether `.lmbake` artifacts belong in Git LFS or stay local, and confirm the proposed 24-light/4096 lightmap budgets.
<!-- resumed 2026-10-13T00:50:54Z by a new session -->
<!-- done:redesign -->
## Redesign: what exists now (2026)
- **Core (new):** `autoload/unreality.gd` (hidden value; `ramp`, `wrongs`, `raise`, `spike`, `set_floor`, `force`, `motion_scale`; sets global shader uniforms `unreality`/`unreal_time`), `scenes/unreality/unreality_model.gd` (pure maths, tested), `autoload/acts.gd` (nine acts, unlocks), `scenes/acts/act_base.gd` + `beat_tracker.gd` + `act_stub.gd` (placeholder used by all nine act scenes), `scenes/fx/unreal_grade.gd` + `post_fx.gdshader` (the screen degrades with Unreality: grade, hue drift, lens warp, wobble, double vision, fleas), `scenes/fx/example_unreal_surface.gdshader` (pattern for materials).
- **Kept systems (from the prototype):** `Dialogue` (JSON, typewriter 38 cps, choices, voice-blips; effects now `unreality`/`spike`/`set`), Interaction (camera ray, [E] prompt, outline), `Audio` (buses, SFX recipes, voice blips, ducking, reverb) + `MusicScore/Sequencer/Instruments` (Moon Waltz), `Cutscene` (letterbox, fades, camera presets, skip, `act_card`), `PauseMenu`/`SettingsPanel`/`GameSettings`, `MoonEye` (code-built moon and eye: `open/close/blink/look_at_point/set_pupil/aim_eye_at`), `LetterUI` (`scenes/ui/letter_ui.gd`, text `data/text/letter.txt`).
- **Removed (recover from tag `v1-gamified`):** HUD, Flea Meter, hearts, Treasure Notepad UI, kick/throw meters, chapters 1-2, primitive props (chandelier/armor/nest/lantern), characters kit, birds/boids/flock, Taurus, title screen. Use them as reference or salvage code (`git show v1-gamified:<path>`), but rebuild to the new quality bar.
- **Tools:** `scripts/tools/run_tests.sh [filter]`, `shot.sh <scene>`, `ensure_godot.sh`, `story_act.sh N`, `save.sh`, `start.sh`. Headless tests prove logic only; mark anything judged on looks "unverified in a real window".
- **Gotchas:** after adding `class_name` scripts run `godot --headless --path . --import`. In screenshot scripts call `cam.make_current()` (the Cutscene autoload owns a camera). Headless prints `Parameter "m" is null` (dummy renderer noise, filtered by run_tests).
