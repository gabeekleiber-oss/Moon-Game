# DIRECTION - the shared notebook for every agent
Read this first. North star = where the game is heading. Log = ideas, decisions, concerns and open questions from every agent (newest last).
Agents never edit this file: write under `## NOTES FOR DIRECTION` in your checkpoint and the save script appends new lines to the Log.
The human edits the North star by hand.

## North star (human-edited)
- **An experience, not a game of scores.** A realistic, unnerving, explorable first-person adaptation of "I've Hung You From the Moon". The player acts out the story, in strict order, across nine acts (docs/ACTS.md). Almost all labour goes into world-building, detail and graphics.
- **World and map first** (docs/WORLD_BIBLE.md): intricate, close to real life, plan-accurate. Then the **art that degrades with Christopher's sanity**: a hidden Unreality value (never shown) bends colour, lens, light, sound, geometry, faces and text (docs/ART_BIBLE.md).
- **Psychological horror**, with a few earned shocks (docs/ACTS.md lists them all). The narrator is cheerful and unreliable; the world gets worse while he smiles.
- The player still *does the book's actions* (kick, broom, drive, climb, carry, chop, light the fire), physically and forgivingly. No health, score, timers, meters or HUD.
- Each act ends with a subtle but noticeable world cue toward the next. Text on screen, a speaking-blip sound per character, no recorded voice.
- Fidelity to the story (CANON.md) first, then the quality of place, then everything else.
- Current milestone: **M1 foundations** (S-01..S-05, S-09, S-12), then **M2 the house**, then a **vertical slice of Act 3**.
- Priority rule: finish things that unblock other tasks; keep the project runnable at every step; verify visuals in a real window (the human) not just software screenshots.

## Open questions
- Realistic faces: author from CC0 bases, or ship the "unfinished face" fallback (ART_BIBLE 6)? Decide after the first character test (S-08).
- Art references (films/paintings/photos) are still wanted from the human (drop in docs/source/refs/).
- Audio: procedural SFX/blips plus CC0 ambience samples (default) or something else?
- The TV scene's real actor name is verbatim in the story: keep (decided); never depict a likeness.

## Log
- [redesign] The v1 chapter prototype (HUD, Flea Meter, hearts, kick/throw meters, primitive props/characters/birds) was removed; it is preserved at git tag `v1-gamified`. Salvage with `git show v1-gamified:<path>`.
- [redesign] Kept and adapted: Dialogue, Interaction, Audio (+ music), Cutscene, PauseMenu/Settings, MoonEye, LetterUI, PostFX (now driven by the hidden Unreality value: scenes/fx/unreal_grade.gd).
- [redesign] New core: `Unreality` autoload (hidden value + global shader uniforms), `Acts` autoload (nine acts, unlock cues), `ActBase` + `BeatTracker`, nine stub act scenes. Dialogue JSON effects are now `unreality`/`spike`/`set`.
