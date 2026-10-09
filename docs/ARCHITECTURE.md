# ARCHITECTURE (Godot 4.3, GDScript)

The PDF brief's Part II is for Three.js. This file is the Godot translation. If they conflict, THIS wins.

## Folder layout
```
autoload/        Events (signal bus), Game (state), ChapterManager, DebugMenu
scenes/main/     Entry
scenes/player/   First-person controller (+ hands/arms later)
scenes/chapters/ chNN_name/chNN_name.tscn (+ scripts, sub-scenes) - one folder per chapter
scenes/ui/       HUD (flea jar, hearts, caption box, objective), notepad, menus
scenes/props/    Reusable props (chandelier, armor, nest, tv, taurus...)
scenes/characters/  Rigged-from-primitives characters (see CHARACTERS below)
scenes/fx/       Post-process, particles, light shafts, moon+eye
scripts/         Shared scripts; ChapterBase (class_name) lives here
data/dialogue/   Dialogue as JSON (one file per scene/chapter)
assets/          models/ textures/ audio/ fonts/
docs/ tests/
```

## Autoloads
| Name | Purpose |
|------|---------|
| Events | Global signal bus (append-only) |
| Game | Flea, hearts, flags, counters, Treasure Notepad, settings, input map |
| ChapterManager | CHAPTERS table; `go_to(id)`, `next()`; one chapter resident at a time |
| DebugMenu | Backtick chapter select + flea slider; `-- --chapter=N` CLI jump |

Proposed (build as needed, announce in HANDOFF first): `Dialogue` (runner), `Audio` (buses + music sequencer), `PostFX`.

## Chapter contract
Every chapter scene's root script `extends ChapterBase` (scripts/chapter_base.gd): set `chapter_id`, `chapter_title`, `objective`,
override `_chapter_ready()`, call `complete()` when the canon beat is done. Must run standalone with F6 (debug N key advances stubs).
Player spawn faces -Z. Units: metres/seconds. Cutscenes: coroutines using `await` + AnimationPlayer/Tween; skippable (hold Space) and
skipping must set all end-state flags/meters.

## Brief (Three.js) -> Godot mapping
| Brief | Godot |
|-------|-------|
| Custom post pass (vignette, grain, chroma, grade, bloom) | `CanvasLayer` + full-screen `ColorRect` with a canvas_item shader reading `hint_screen_texture`; plus `WorldEnvironment` glow/adjustments/fog. Uniforms driven by Flea Meter. |
| Per-chapter fog/grade | `Environment` resource per chapter (fog, tonemap, adjustment) + hero light |
| Light shafts | Additive translucent cone MeshInstance3D, or FogVolume |
| Canvas procedural textures | `NoiseTexture2D`, `GradientTexture2D`, `ImageTexture` generated in GDScript, or shaders; hand-painted textures also OK |
| Particles (fleas, dust, embers...) | `GPUParticles3D` / `CPUParticles3D`; screen-edge fleas via shader or 2D particles |
| Instancing | `MultiMeshInstance3D` for birds, candles, armor, trees |
| Outline highlight | Next-pass inverted-hull material or shader on interact target |
| Procedural audio | `AudioStreamGenerator` for synthesized SFX/music; OR free CC0 samples (decision pending - see TASKS T-002) |
| 3-bus audio | `AudioServer` buses: Master / Music / SFX / Amb / Voice; reverb on a bus |
| Voice blips | Short generated tones per character synced to typewriter text |
| Physics (thrown objects) | `RigidBody3D` |
| Characters from primitives | Node3D hierarchies of CSG/Mesh primitives + AnimationPlayer (procedural) |
| Moon + eye | Sphere + shader; eye = recessed socket, lid meshes, cornea (transparent), iris texture; reused in title, Ch5, windows in Ch6/8/9, finale |
| Dialogue as data | JSON in data/dialogue; one canon choice per fork (`canon: true`), others funnel back in 1-2 nodes |
| Quality toggle (Auto/High/Low) | Viewport scaling + disable post/shadows/glow |
| Debug (?chapter=N) | CLI `-- --chapter=N` + DebugMenu |

## Dialogue JSON shape
```json
{"id":"moon_01","start":"a","nodes":{
 "a":{"who":"moon","text":"...","next":"b"},
 "c":{"who":"moon","text":"...","choices":[
   {"text":"...","goto":"d","flea":3,"heart":{"self":-1},"set":"rudeToMoon"},
   {"text":"...","goto":"d","flea":-2,"canon":true}]}}}
```
Node may carry: `cam`, `sfx`, `emote`, `wait`. Typewriter 38 cps; 180ms pause after . ? !; 90ms after commas.

## Interactable contract
Group `interactable`; script exposes `prompt: String`, `range := 2.4`, `can_use() -> bool`, `use(player)`; runs once if `once`.
Player raycasts from camera, shows `[E] prompt` and a reticle dot.

## Performance targets
~300 draw calls, ~300k visible tris per scene; max 2 shadow-casting lights (1 preferred); MultiMesh for anything repeated >10x;
one chapter resident at a time (free previous completely); adaptive quality step-down: resolution scale -> glow -> shadows -> post.

## Characters
Christopher (1st person; hands/forearms visible), Elsa Ray (blue eyes, signature half-second glare), Mary Sue (gold hair, gold-speckled cone hat),
Frank (stern, still, sly smile = Clement), Sweaty Man (steam shimmer, very long finger), The Errante (moon only), Clement (seated, still),
Edith (silhouette only), 12 bird species + kite flock, gold statues, the racoon. Built from primitives; face swap via texture/expression atlas.

## Physics layers
1 world, 2 player, 3 enemies/birds, 4 interactables, 5 projectiles/throwables

## Cut order if short on budget
Tier 3: credits, touch controls, extra paintings, Appraisal Gaze polish. Tier 2: flute mini-game, whisky blur, chop depth, cyclone depth.
Tier 1 (never cut): canon beats of every chapter, moon with eye, Flea Meter, letter, TV+broom, the drive, dome dialogue,
birthday transformation, lake with "Hello, son", Gronfiser verse, statue-room flea takeover, the fire.
