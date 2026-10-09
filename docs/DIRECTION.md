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
