# HANDOFF (newest first). Written by scripts from finished tasks' HANDOFF NOTEs. Do not edit by hand.


<!-- done:F-11 -->
## F-11 done (2026-10-11)
- Files: scenes/birds/{bird_species,bird_mesh,hero_bird,boids,flock}.gd, bird.gdshader. Tests: tests/test_birds; shots: tests/_bird_shot, tests/_flock_shot (cam.make_current()).
- BirdSpecies.get_species(0..11) = 12 palettes {id,name,body,belly,wing,head,beak,eye,size}. BirdMesh.build(species) -> ~300-tri ArrayMesh facing -Z, feet at y=0, ~0.16 m long.
- HeroBird: `var b := HeroBird.new(); b.species = 4; b.hero_scale = 2.5; add_child(b)`; perch(), fly(bool), look_at_point(world, s), hop(), set_species(i), species_id(). Idle bob stops under Reduced Motion.
- Flock: `var f := Flock.new(); f.count = 90; f.bounds = AABB(...) (local space); add_child(f)`; set_attractor(p) / clear_attractor(), scare(from, radius, strength), set_active(bool), bird_position(i). Count clamps to 60-120. 12 MultiMeshes total.
- Boids (pure RefCounted, deterministic by seed) is reusable for other swarms; step(delta), set_attractor, scare.
- Gotchas: new class_name scripts need `godot --headless --path . --import` before tests. No colliders. Birds do not avoid walls; keep bounds inside the room.

<!-- done:F-11 -->
## F-11 done (2026-10-11)
- Files: scenes/birds/{bird_species,bird_mesh,hero_bird,boids,flock}.gd, bird.gdshader. Tests: tests/test_birds; shots: tests/_bird_shot, tests/_flock_shot (cam.make_current()).
- BirdSpecies.get_species(0..11) = 12 palettes {id,name,body,belly,wing,head,beak,eye,size}. BirdMesh.build(species) -> ~300-tri ArrayMesh facing -Z, feet at y=0, ~0.16 m long.
- HeroBird: `var b := HeroBird.new(); b.species = 4; b.hero_scale = 2.5; add_child(b)`; perch(), fly(bool), look_at_point(world, s), hop(), set_species(i), species_id(). Idle bob stops under Reduced Motion.
- Flock: `var f := Flock.new(); f.count = 90; f.bounds = AABB(...) (local space); add_child(f)`; set_attractor(p) / clear_attractor(), scare(from, radius, strength), set_active(bool), bird_position(i). Count clamps to 60-120. 12 MultiMeshes total.
- Boids (pure RefCounted, deterministic by seed) is reusable for other swarms; step(delta), set_attractor, scare.
- Gotchas: new class_name scripts need `godot --headless --path . --import` before tests. No colliders. Birds do not avoid walls; keep bounds inside the room.

<!-- done:F-08 -->
## F-08 done (2026-10-11)
- Files: scenes/audio/{synth,sfx_recipes,voice_profiles,audio}.gd. `Audio` is an autoload (project.godot). Everything is procedural (AudioStreamWAV from Synth); no audio asset files.
- Buses (all -> Master, which GameSettings owns): Music, SFX, Amb, Voice. SFX/Amb/Voice have a reverb (dry until set); Music/Amb have a duck (Amplify) and a pause-muffle (LowPass).
- API: Audio.play_sfx(name, db, pitch) / play_sfx_at(name, pos, db, pitch) / play_stream(stream, bus, db, pitch) / set_reverb("none|room|hall|dome|cave") / set_bus_volume(bus, 0..1) / duck(db) / unduck() / blip(who, ch). Names: SfxRecipes.NAMES (16).
- Automatic: voice blips from Events.speaker_blip; dialogue `sfx` cues; -8 dB duck during dialogue; muffle on pause; chime on notepad items; heart and flea sounds; click on interact; reverb reset on chapter_started.
- For F-09 (music): play on the "Music" bus via Audio.play_stream(stream, "Music", db) or your own AudioStreamPlayer with bus="Music"; ducking and pause-muffling then apply for free. Loop with Synth.to_stream(buf, true).
- Add a sound: new name in SfxRecipes.NAMES + a branch in _build (keep < 1.5 s, peak < 1). Gotchas: new class_name scripts need `godot --headless --path . --import` before tests; headless timers run faster than wall-clock (reset Audio._last_ms in tests).
- Tests: test_audio_synth, test_audio, test_audio_voice, test_audio_events (all pass headless). Audition by ear: tests/_audio_demo.tscn (F6).

<!-- done:F-07 -->
## F-07 done (2026-10-11)
- Class `MoonEye` (scenes/moon/moon_eye.gd, scene moon_eye.tscn; F6 demo moon_eye_demo.tscn: mouse = gaze, O/C/B/P keys). Built entirely in code; `radius` (default 10 m), `eye_enabled`, `start_open`, `glow` are exports. Eye faces local +Z.
- API: `open(s)`, `close(s)`, `blink(s)` return a Tween (`await moon.open(1.2).finished`; null if eye_enabled is false); signals `opened`, `closed`, `blinked`. `look_at_point(world_pos, s)` (clamped ~32 deg), `look_forward()`, `set_pupil(0..1, s)`, `aim_eye_at(world_pos)` turns the whole moon to face a point, `is_open()`, `eye_world_position()`, `openness` property 0..1 (set directly for scripted lids).
- Gotchas: lids start closed. `eye_enabled=false` = blank moon (no eye nodes). Lid skin uses its own crater pattern so a slight seam vs the moon is possible. Look was only checked in software-rendered screenshots. It does not move or animate by itself; callers drive it (the demo shows idle blinks). Shot tool: tests/_moon_shot.tscn (call cam.make_current()).

<!-- done:F-07 -->
## F-07 done (2026-10-11)
- Class `MoonEye` (scenes/moon/moon_eye.gd, scene moon_eye.tscn; F6 demo moon_eye_demo.tscn: mouse = gaze, O/C/B/P keys). Built entirely in code; `radius` (default 10 m), `eye_enabled`, `start_open`, `glow` are exports. Eye faces local +Z.
- API: `open(s)`, `close(s)`, `blink(s)` return a Tween (`await moon.open(1.2).finished`; null if eye_enabled is false); signals `opened`, `closed`, `blinked`. `look_at_point(world_pos, s)` (clamped ~32 deg), `look_forward()`, `set_pupil(0..1, s)`, `aim_eye_at(world_pos)` turns the whole moon to face a point, `is_open()`, `eye_world_position()`, `openness` property 0..1 (set directly for scripted lids).
- Gotchas: lids start closed. `eye_enabled=false` = blank moon (no eye nodes). Lid skin uses its own crater pattern so a slight seam vs the moon is possible. Look was only checked in software-rendered screenshots. It does not move or animate by itself; callers drive it (the demo shows idle blinks). Shot tool: tests/_moon_shot.tscn (call cam.make_current()).

<!-- done:F-06 -->
## F-06 done (2026-10-11)
- Files: scenes/menus/{game_settings,settings_panel,pause_menu,notepad_view}.gd. PauseMenu is an autoload (Esc pause, Q notepad).
- API: PauseMenu.open_pause()/open_notepad()/close()/is_open(); Events.game_paused(bool); GameSettings.set_value(key, v) (clamp, apply, save, Events.settings_changed); Game.settings["assist"|"reduced_motion"|...]; NotepadView.new() is reusable (reads Game.notepad, auto-refreshes).
- Add treasures with Game.add_notepad_item(id, name, value, room): a toast appears at top-centre even when not paused; duplicate ids are ignored.
- Esc/Q are ignored during Cutscene.is_active(). Gotcha: after adding a new class_name script, run `godot --headless --path . --import` before tests or the class is not found.
- Tests: tests/test_settings, test_settings_panel, test_pause, test_notepad (all pass headless). Godot 4.3 binary can be fetched from GitHub releases in the sandbox.
<!-- resumed 2026-10-11T15:54:59Z by a new session -->
<!-- done:F-07 -->
## F-07 done (2026-10-11)
- Class `MoonEye` (scenes/moon/moon_eye.gd, scene moon_eye.tscn; F6 demo moon_eye_demo.tscn: mouse = gaze, O/C/B/P keys). Built entirely in code; `radius` (default 10 m), `eye_enabled`, `start_open`, `glow` are exports. Eye faces local +Z.
- API: `open(s)`, `close(s)`, `blink(s)` return a Tween (`await moon.open(1.2).finished`; null if eye_enabled is false); signals `opened`, `closed`, `blinked`. `look_at_point(world_pos, s)` (clamped ~32 deg), `look_forward()`, `set_pupil(0..1, s)`, `aim_eye_at(world_pos)` turns the whole moon to face a point, `is_open()`, `eye_world_position()`, `openness` property 0..1 (set directly for scripted lids).
- Gotchas: lids start closed. `eye_enabled=false` = blank moon (no eye nodes). Lid skin uses its own crater pattern so a slight seam vs the moon is possible. Look was only checked in software-rendered screenshots. It does not move or animate by itself; callers drive it (the demo shows idle blinks). Shot tool: tests/_moon_shot.tscn (call cam.make_current()).

<!-- done:F-05 -->
## F-05 done (2026-10-11)
- Autoload `Cutscene` (scenes/cutscene/cutscene.gd). `var skipped: bool = await Cutscene.play(func() -> void: ...)` runs a sequence; inside use `await Cutscene.wait(s)`, `fade_out(s, color)`, `fade_in(s)`, `letterbox(on, s)`, `title_card(text, sub, hold, kicker)`, `Dialogue.play(...)`.
- Camera: `await Cutscene.cam("wide"|"medium"|"close"|"low"|"high"|"top"|"dutch", target_or_null, seconds, behind)`, `cam_to(transform, fov, s)`, `cam_release(s)` (play() releases for you), `Cutscene.focus`, `shake(amount, s)`.
- `await Cutscene.chapter_card(id)` = fade to black, "CHAPTER n" + title from ChapterManager, fade back; standalone or inside play().
- While active: HUD hidden (previous state restored), player cannot move/look/jump, interaction reticle/ray off. Events: cutscene_started(id), cutscene_ended(id, skipped). `Cutscene.is_active()`, `is_skipping()`, `request_skip()`.
- Gotchas: finish your sequence with the screen visible (call fade_in) unless staying black is intended; a skip that happens mid-dialogue stops the dialogue (effects already reached stay applied).

<!-- done:F-03 -->
## F-03 done (2026-10-09)
- Autoload `Hud` (scenes/hud/hud.gd, CanvasLayer 8). Nothing to add per chapter: it listens to Events.
- Objective line: `Events.objective_set(text)` (ChapterBase already does this); empty text hides it. Toast: `Events.show_message(text)` (3 s).
- Meters: top-left flea jar (Game.flea 0-100) and 4 hearts (elsa, mary_sue, frank, self; 0-10). Change them only through Game.add_flea / set_flea / add_heart; the Hud redraws and spawns floating ticks ("+3 fleas", "-1 Frank").
- Captions: `Hud.caption(who, text, seconds=-1)` or `Events.caption(who, text)`; shown only when no dialogue is running. `Hud.clear_caption()`, `Hud.is_caption_visible()`.
- `Hud.set_hud_visible(false/true)` hides or shows everything (title screen, cutscenes).
- Reduced Motion (Game.settings.reduced_motion) stops flea hopping, heart pulses and rising ticks; they only fade.
- Test: godot --headless --path . res://tests/test_hud.tscn
- Gotcha: look not checked in a real window. Autoload name Hud means no class_name Hud may be declared.

<!-- done:F-03 -->
## F-03 done (2026-10-09)
- Autoload `Hud` (scenes/hud/hud.gd, CanvasLayer 8). Nothing to add per chapter: it listens to Events.
- Objective line: `Events.objective_set(text)` (ChapterBase already does this); empty text hides it. Toast: `Events.show_message(text)` (3 s).
- Meters: top-left flea jar (Game.flea 0-100) and 4 hearts (elsa, mary_sue, frank, self; 0-10). Change them only through Game.add_flea / set_flea / add_heart; the Hud redraws and spawns floating ticks ("+3 fleas", "-1 Frank").
- Captions: `Hud.caption(who, text, seconds=-1)` or `Events.caption(who, text)`; shown only when no dialogue is running. `Hud.clear_caption()`, `Hud.is_caption_visible()`.
- `Hud.set_hud_visible(false/true)` hides or shows everything (title screen, cutscenes).
- Reduced Motion (Game.settings.reduced_motion) stops flea hopping, heart pulses and rising ticks; they only fade.
- Test: godot --headless --path . res://tests/test_hud.tscn
- Gotcha: look not checked in a real window. Autoload name Hud means no class_name Hud may be declared.
<!-- done:F-04 -->
## F-04 done (2026-10-10)
- Autoload `PostFX` works by itself: chapter_started -> that chapter's grade, flea_changed -> flea overlay.
- Chapter scripts: `PostFX.set_grade("ch07_kitchen", 2.0)` (named, eased) or `PostFX.set_grade({"saturation": 0.4}, 1.0)` (partial); `PostFX.set_param(name, value)`; `PostFX.set_enabled(false)`. Grade names: GradeTable.names().
- Edit looks in scenes/fx/grade_table.gd (keys are shader uniform names); shader in scenes/fx/post_fx.gdshader.
- Gotcha: effects read the 3D scene only because the pass sits under HUD layers (>=10); a new CanvasLayer you want graded must use layer < 5.

<!-- done:F-01 -->
## F-01 done (2026-10-09)
- Play: `await Dialogue.play("moon_01")` (loads res://data/dialogue/moon_01.json; full res:// paths also work). Returns true when finished, false if invalid/busy. `Dialogue.is_active()`, `Dialogue.stop()`, `Dialogue.log()` (last 12 lines; player picks have who "you"), `Dialogue.load_data(id)` to validate without playing.
- JSON shape: docs/ARCHITECTURE.md. Extras: `wait`, `cam`/`sfx`/`emote` (-> Events.dialogue_cue), effects `flea`/`heart`/`set` on nodes or choices. 1-4 choices; exactly one `canon: true` per fork; others must funnel back to canon within 2 nodes (else a warning in the console).
- Events: dialogue_started/ended(id), dialogue_line(who,text), caption(who,text), dialogue_choice_made(i,text), dialogue_cue(kind,value), speaker_blip(who,ch).
- Input in the box: E/Space/Enter/click skips typing then advances; 1-4 or click picks. 0.2 s input guard so the [E] that opened it does not skip line 1.
- Tests: `godot --headless --path . res://tests/test_dialogue.tscn` (and test_dialogue_flow.tscn). Scene tests only; `-s` scripts can't see autoloads.
- Gotcha: headless Godot cannot capture the mouse, so UI/mouse paths are only verified by logic, not visually.

<!-- done:F-02 -->
## F-02 done (2026-10-09)
- Make an interactable: add `Interactable` (scenes/interaction/interactable.gd, class_name Interactable) + CollisionShape3D + meshes; set `prompt`, `message` (funny reply), `once`, `range` (default 2.4), `set_flag_on_use`.
- React: connect its `used(player)` signal, or extend and override `_on_use(player)`. Toggle with `enabled`; `reset_use()` re-arms a `once` object.
- Events: `Events.interact_focus_changed(target|null)`, `Events.interacted(target)`. Non-Interactable nodes work if in group `interactable`, layer 4, with prompt/range/can_use()/use().
- The player already gets an InteractionRay (+ reticle/prompt HUD) on its Camera3D from player.gd; nothing to add per chapter.
- Gotcha: the ray ignores interactables while a dialogue runs (dialogue_started/ended) and while the mouse is not captured.
## v0.4 - setup
Switched to a flat shared task queue (no roles). Existing: Game state (Flea, Hearts, flags, Notepad), ChapterManager, DebugMenu (backtick),
ChapterBase (`scripts/chapter_base.gd`), 11 chapter stubs (press N to advance in debug), first-person player (`scenes/player/`), Events bus.
