# ARCHITECTURE (Godot 4.3, GDScript)

This is the code contract. If another doc disagrees about CODE, THIS wins. (The old PDF brief targeted Three.js and no longer applies.) The previous prototype lives at git tag `v1-gamified`.

## Folder layout
```
autoload/          Events (signal bus), Game (flags/settings), Unreality (hidden insanity value), Acts (act loader), DebugMenu
scenes/main/       Entry (boots Act 1, or `-- --act=N --unreality=0.6`)
scenes/acts/       actNN_name/actNN_name.tscn (one folder per act), act_base.gd, beat_tracker.gd, act_stub.gd (placeholder)
scenes/unreality/  UnrealityModel (pure maths)
scenes/world/      (new) RoomBuilder, WrongnessDirector, room kit, door/lock helpers
scenes/player/     First-person controller (+ hands, carry, later)
scenes/interaction/ Interactable base, camera ray, in-world prompt/outline
scenes/dialogue/   Dialogue autoload, runner, on-screen text presenter (narration/verse/speech)
scenes/audio/      Audio autoload (buses, sfx, voice blips, reverb), music (score, sequencer, instruments)
scenes/fx/         PostFX autoload, UnrealGrade, shaders (post_fx.gdshader, example_unreal_surface.gdshader)
scenes/cutscene/   Cutscene autoload (letterbox, fades, camera presets, skip)
scenes/menus/      Pause menu, settings panel/model
scenes/moon/       MoonEye (the moon and its eye)
scenes/ui/         LetterUI (the damp letter); other diegetic UI
data/world/        Room JSON (see WORLD_BIBLE); data/dialogue/ JSON; data/text/ plain text (the letter)
assets/            models/ textures/ audio/ fonts/ + assets/LICENSES.md (every external asset, with license + URL)
docs/ tests/ scripts/tools/
```

## Autoloads (order matters)
| Name | Purpose |
|---|---|
| Events | Global signal bus (append-only). Act, beat, cue, unreality, dialogue, interaction, cutscene, settings, pause signals. |
| Game | `flags`, `counters`, `settings`, `furthest_act`, input map. **No score, health or meters.** |
| Unreality | The hidden insanity value 0..1: `level`, `ramp(a,b)`, `band()`, `wrongs(id,bias)`, `raise`, `spike`, `set_floor`, `force`, `motion_scale()`; also sets the **global shader uniforms** `unreality` and `unreal_time`. |
| Acts | `ACTS` table, `go_to(id, force)`, `transition_to(id)`, `go_to_next()`, `unlock(id)`, `is_unlocked(id)`, `title_of(id)`. One act resident at a time. |
| DebugMenu | Backtick: act select (ignores locks) + Unreality slider. |
| Dialogue | Plays dialogue JSON with the on-screen text box. |
| PostFX | Full-screen pass: location mood + Unreality curves (`set_base_grade`). |
| Cutscene | Letterbox, fades, camera presets, hold-Space skip, `act_card`. |
| PauseMenu | Esc menu, settings, in-world message toast (`Events.show_message`). |
| Audio | Buses, SFX recipes, voice blips, ducking, reverb presets. |

## Act contract
An act is a scene whose root extends `ActBase` (`scenes/acts/act_base.gd`):
1. Set `act_id`, `act_title`, `unreality_floor`, `base_grade` (exports). `_ready` sets the floor, eases PostFX to the grade and emits `Events.act_started`.
2. Override `_define_beats(t: BeatTracker)`: list beats **in story order** using the ids in `docs/ACTS.md` (`t.add("finger")`; use `requires` + `chain=false` for free-order beats).
3. Override `_act_ready()` to build/dress the act. Call `beat("id")` when the player does the thing (out-of-order calls are ignored).
4. The last beat completes the act: `Events.act_completed`, then `_fire_unlock_cue()` (override: make the world show where to go next), then `Acts.unlock(next)`.
5. **The player chooses when the next act starts.** After the cue, call `make_exit(pos, size)` (or your own Interactable) so the player walks/uses it to trigger `Acts.transition_to(next)` (fade -> load -> fade). Never auto-advance.
Act scenes must run standalone (F6) and via `-- --act=N`. `act_stub.gd` is the placeholder every act currently uses; replace it act by act.

## Unreality contract
* **Read** the level with `Unreality.ramp(a,b)` (smooth 0..1) or `Unreality.level`; never gate on `band()` alone. Decide *which* objects go wrong with `Unreality.wrongs("stable_id")`.
* **Write** it from story code only: `raise(x)` (permanent), `spike(x)` (decays), `set_floor(x)` (the act does this), `force(x)` (debug/cutscene).
* **Moving effects multiply `Unreality.motion_scale()`** (0 when Reduced Motion). Colour/audio effects need not.
* **Shaders:** read `global uniform float unreality;` and `unreal_time` (registered in `project.godot` `[shader_globals]`). See `scenes/fx/example_unreal_surface.gdshader`.
* Effects must be **subtle, accumulating and never while observed** (ART_BIBLE). The player never sees a number; do not add any UI that reveals it (the debug menu is the only exception).
* Tests: the maths is in `UnrealityModel` (pure); test world behaviours by calling `Unreality.force(level)` then asserting your effect.

## Interactable contract
Group `interactable`; script exposes `prompt: String`, `range := 2.4`, `can_use() -> bool`, `use(player)`; runs once if `once`. The camera ray finds it, shows a minimal in-world hint and highlight, and emits `Events.interacted`. Optional `message` is shown through `Events.show_message` (a quiet toast). Prefer diegetic prompts over UI text where you can.

## Dialogue JSON shape
```json
{"id":"moon_01","start":"a","nodes":{
 "a":{"who":"moon","text":"...","next":"b"},
 "c":{"who":"moon","text":"...","choices":[
   {"text":"...","goto":"d","unreality":0.03,"set":"rudeToMoon"},
   {"text":"...","goto":"d","spike":0.15}]}}}
```
Node effects: `unreality` (permanent rise), `spike` (jolt), `set` (flag). Node may carry `cam`, `sfx`, `emote`, `wait`. Typewriter 38 cps; +180 ms after . ? !; +90 ms after commas; a voice-blip per character (`scenes/audio/voice_profiles.gd`). There are no health/score effects. Text is on screen; there is no recorded voice.

## Assets and materials
* Free, license-clean assets only; **every external asset gets a line in `assets/LICENSES.md`** (name, author, license, URL, where used). CC0 first (Poly Haven, ambientCG, Quaternius, Kenney). No asset without its license line.
* Import settings and naming: `assets/models/<area>/<name>.glb`, `assets/textures/<set>/<set>_{albedo,normal,roughness,ao}.png`; one material per surface set in `assets/materials/`.
* Always provide a code-built fallback so scenes run without the asset (mark `# PLACEHOLDER`).
* Surface materials of importance read the global unreality uniforms (ART_BIBLE).

## Performance
60 fps on a mid-range PC at 1080p. Rooms stream per wing; baked lighting for interiors; <= 2 shadow-casting dynamic lights per view; MultiMesh/instancing for anything repeated >10x; LODs and occlusion; one act resident at a time (free the previous completely). Adaptive quality: resolution scale -> glow -> shadows -> post. Probe frame time in any scene you add (`S-12`).

## Physics layers
1 world, 2 player, 3 characters/birds, 4 interactables, 5 carryables/projectiles.

## Cut order if short on budget
Tier 3: extra paintings, ambient creatures, secondary props. Tier 2: shock polish, second variants of wrongness. **Tier 1 (never cut):** the plan-accurate mansion, the moon with its eye, the Unreality art layer, the letter, the TV and broom, the drive, the dome dialogue, the dark-house sequence, the birthday transformation, the lake with "Hello, son", the Gronfiser verse, the enfilade, the fire and the final image.
