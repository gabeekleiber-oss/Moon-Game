# HANDOFF (newest first). Written by scripts from finished tasks' HANDOFF NOTEs. Do not edit by hand.


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
