# DIRECTION - the shared notebook for every agent
Read this first. North star = where the game is heading. Log = ideas, decisions, concerns and open questions from every agent (newest last).
Agents never edit this file: write under `## NOTES FOR DIRECTION` in your checkpoint and `apply_output.sh` appends new lines to the Log.
The human edits the North star by hand.

## North star (human-edited)
- A 3D first-person narrative adventure in Godot 4.3. Every chapter is a hand-built diorama with a real mechanic, ~25-40 min total.
- Tone: Wes Anderson dollhouse x fever dream x Dr. Seuss. Sincere comedy over real grief. No jump scares, no gore.
- Fidelity to the story (CANON.md) first, then visual richness, then playability, then embellishment.
- Current milestone: M1 - core systems (dialogue, interaction, HUD, post-fx, moon+eye) then Ch1-3 as a vertical slice.
- Priority rule: finish things that unblock other tasks before polishing; keep the project runnable at every step.

## Open questions for the human
- Source story text for verbatim passages (letter, moon dialogue, Gronfiser verse, Elsa lines): not provided yet.
- Audio: procedural SFX/blips (default) vs free CC0 samples.

## Log (script-appended; format: `- [TASK] note`)
- [F-02] Headless Godot 4.3 works for tests: scene-based tests (not `-s`, which cannot see autoloads). Run `godot --headless --path . res://tests/<name>.tscn`; `Input.mouse_mode` cannot be captured headless.
- [F-02] Interaction visuals (outline width/colour, prompt style) were not eyeballed in a real window; tune in interact_outline.gdshader / interaction_hud.gd.
- [F-01] Dialogue JSON can carry effects on nodes or choices: flea (number), heart ({"elsa": -1}), set (flag or array). Write unknown story text as TODO_VERBATIM; the validator counts them.
- [F-01] Display names are who.capitalize() (e.g. elsa_ray -> "Elsa Ray"); a name table can be added to DialogueBox._display_name if needed.
- [F-01] DialogueBox look (colours, size) was not eyeballed in a window; tune in scenes/dialogue/dialogue_box.gd.
- [F-03] Cutscenes (F-05) should call `Hud.set_hud_visible(false)` and show it again afterwards; the interaction prompt and dialogue box are separate layers.
- [F-03] The Hud look (jar, hearts, colours, positions) was not eyeballed in a real window; tune the constants and _draw code in scenes/hud/hud.gd.
- [F-03] Booting the game headless prints `ERROR: Parameter "m" is null.` once. It also happens on the commit before F-03, so it is not from the HUD; likely a mesh/material call that needs a renderer.
- [F-04] Software rendering works in the sandbox (xvfb + gl_compatibility), so agents can screenshot scenes and shaders; headless alone cannot compile shaders.
- [F-04] Chapter lights/fog should carry most of the mood; PostFX only ties the frame together. Tune grade strength in scenes/fx/grade_table.gd once real chapter lighting exists.
- [F-04] FOV breathing (flea 70+) still needs doing on the player camera; respect reduced_motion.
- [F-05] Cutscenes are plain coroutines: `await Cutscene.play(func(): ...)`. Put ALL end-state changes in the sequence body (never behind `if not skipped`); skipping fast-forwards through it.
- [F-05] Dialogue JSON `cam` cue now works: `"cam": "close"` frames Cutscene.focus (set it once: `Cutscene.focus = anchor`), `"cam": "release"` returns to the player camera.
- [F-05] Chapters can opt into automatic title cards with `Cutscene.auto_title_cards = true` or call `await Cutscene.chapter_card(id)` from _chapter_ready().
- [F-07] [F-07] MoonEye (scenes/moon/moon_eye.gd): `add_child(MoonEye.new())`, `await moon.open(1.2).finished`, `blink()`, `look_at_point(world)`, `set_pupil(0..1)`, `aim_eye_at(world)`; `eye_enabled=false` for a blank sky moon.
- [F-07] [F-07] In standalone screenshot scripts call `cam.make_current()`; the Cutscene autoload's camera otherwise wins and the 3D scene renders empty.
- [F-06] Human: `assist` setting is undefined in the docs; assumed = interaction reach x1.5 (Game.settings["assist"]). Define it if it should mean more.
- [F-06] Notepad value unit (dollars? "worth"?) is undefined; shown as plain numbers. Decide before C-10.
- [F-06] Menus/notepad were screenshotted in xvfb (tests/_menu_shot.tscn); notepad paper sits inside the dark pause frame, could be unframed later.
- [F-08] Human: nobody has HEARD the audio (agents have no speakers). Run tests/_audio_demo.tscn (F6) to audition all SFX, voices and reverbs, then report what to retune (recipes in scenes/audio/sfx_recipes.gd, voices in voice_profiles.gd).
- [F-08] Real dialogue speaker ids are not known yet; voices match by keyword (elsa, mary, frank, sweaty, clement, edith, gronfiser, moon...). Chapter authors: use those words in `who`, or add a key to VoiceProfiles.PROFILES.
- [F-08] Chapters should call Audio.set_reverb("hall"/"dome"/"cave"...) in _chapter_ready(); it resets to "none" on every chapter_started.
- [F-10] [F-10] Chandelier: `var c := Chandelier.new(); c.variant = Chandelier.Variant.RUBY; c.arms = 12; add_child(c)`; hangs from its origin; `set_lit(false)` for dark rooms. Shared mesh helpers in scenes/props/prop_util.gd (PropUtil).
- [F-10] [F-10] Armor: `Armor.new()` (finish STEEL/BLACK/BRASS, pose REST/SALUTE/GUARD, halberd) = 16 named pieces for the Ch10 Military Gallery (needs 12+); `piece_count()` / `piece_names()` for Notepad rows. No collider included.
- [F-10] [F-10] BirdNest (`eggs`, `seed_value`) and NestLantern (12 arms, `set_lit`, `nests()`) are ready for Ch6 and the Bird Room; the lantern is the 12-arm light the chapter needs.
- [F-10] [tooling] New scripts: `bash scripts/tools/run_tests.sh [filter]` runs all headless tests (non-zero exit on fail, filters the renderer noise); `shot.sh <scene>` renders screenshots in software GL; `ensure_godot.sh` finds/downloads Godot 4.3. save.sh now auto-resolves TASKS.md rebase conflicts. Run the tests before STATUS: DONE.
- [F-10] [tooling] Repo-mode bundles now start with a MODE: REPO block saying the zip wording does not apply. CI file is parked in docs/ci/ until a token with `workflow` scope (or the human) moves it to .github/workflows.
- [F-11] Birds: HeroBird (scenes/birds/hero_bird.gd) and Flock (flock.gd, 60-120 birds, bounds in local space, set_attractor/scare). Flock bird_scale default 3.
- [F-11] Test scenes need Environment.ambient_light_source = AMBIENT_SOURCE_COLOR, else ambient comes from the background colour and everything renders near-black.
- [F-11] Flock and bird look were checked in software GL only, not a real window; tune bird_mesh.gd proportions and bird.gdshader.
- [F-13] Title screen rhyme line is an agent-written placeholder, not from the source story: human, please provide the real line (TODO_VERBATIM).
- [F-13] Title screen look was checked in software GL screenshots only; tune moon position/UI in scenes/title/title_screen.gd.
