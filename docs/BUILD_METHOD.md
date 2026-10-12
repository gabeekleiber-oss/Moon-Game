# Build Method: the experience is the product

This document is the implementation contract for every future agent. It translates the creative direction into repeatable engineering decisions. If a local task brief conflicts with this file, `docs/CANON.md` still controls story facts, `docs/source/STORY.md` remains immutable, and `docs/ARCHITECTURE.md` controls code APIs. Ask only when a genuine story ambiguity or irreversible scope decision blocks work; otherwise inspect the repository and proceed.

## 1. The north star

Build a first-person, atmospheric adaptation of *I've Hung You From the Moon*. The player inhabits Christopher and physically performs the story's actions. This is an experience game, not a challenge loop. Spend the majority of production effort on believable spaces, precise lighting, materials, set dressing, character presence, environmental sound, and small, carefully staged surreal changes.

The world should feel open while the story remains linear:
- The current act is a walkable place, not a corridor of objective markers. Include optional rooms, sightlines, believable clutter, and time to look around.
- Required story beats may be completed in any sensible order unless the source explicitly requires order.
- The next act never starts automatically. After the current act is complete, an in-world visual and/or audio cue quietly indicates the next physical action. The player chooses to approach/use the exit, enter the car, climb into the dome, lie down, or otherwise trigger the transition.
- Do not add a minimap, quest log, objective list, collectibles, scoring, health, stamina, timers, or a visible insanity meter. Use environment and sound to guide the player.
- Use first-person hands/body presence where the action benefits from it. Interactions should be forgiving and tactile rather than skill tests.

## 2. The Unraveling / Unreality model

The hidden Unreality system is the main long-term progression system. It is never shown as a number to the player. Acts establish a rising floor; meaningful beats may raise the persistent level; a shock may create a temporary spike that recedes. Do not add competing sanity/insanity systems.

Unreality must be experienced through several channels, with restrained escalation:
1. **Space and props:** a portrait's gaze, a subtly wrong count, an object moved only when unseen, a door/corridor that contradicts the remembered layout.
2. **Light and material:** motivated practical lighting first; later, wrong colour temperature, shadows, dampness, surface crawl, impossible reflections.
3. **Sound:** specific room tone, distance/occlusion, silence, slightly detuned motifs, delayed/doubled voices and rare whispers.
4. **People and text:** held expressions, altered age/likeness, voice-blip timing, verse layout and small narration distortions.
5. **Camera/post effects:** a restrained final layer, not the whole horror effect.

Rules:
- Prefer authored, stable IDs and deterministic activation so the same playthrough can be tested.
- Never make an object change while directly observed unless it is an explicitly authored story shock.
- Early changes should be deniable. Escalation should feel cumulative, not random or constantly loud.
- Preserve the story's specific surreal imagery. Do not replace it with generic gore, monsters, or jump scares.
- All motion-driven effects respect Reduced Motion. Avoid rapid flashing and avoid making the game physically uncomfortable by default.
- The debug menu may expose Unreality for developers; player-facing UI must not.

## 3. Canon and data integrity

- `docs/source/STORY.md` is the immutable source text. Never edit, spell-correct, paraphrase, reformat, or replace it.
- Preserve the October 12, 2026 story-beat data in `data/story/beats.json` and the existing world data in `data/world/` unless the human explicitly requests a data change. Add derived implementation around these sources rather than silently rewriting them.
- The nine acts remain in the source's order. Preserve named actions, props, timing, relationships, and intentional ambiguities. Do not invent explanations for unexplained events.
- A summary, interaction prompt, or implementation comment is not a substitute for verbatim text. For exact text, use `docs/source/STORY.md` and `bash scripts/tools/story_act.sh N`.
- A visual embellishment may deepen a scene but must not change what happened. Never depict a real person's likeness just because the text names them.
- Do not create a parallel project, duplicate data source, or `redesign/` folder. Work in the existing Godot project and its established folders.

## 4. Where work belongs

| Concern | Canonical location |
|---|---|
| Creative priorities and player experience | `docs/VISION.md` |
| Act order, beats, interactions, cues and shocks | `docs/ACTS.md`, `data/story/beats.json` |
| Physical floor plans, room IDs, routes and dressing | `docs/WORLD_BIBLE.md`, `data/world/*.json` |
| Visual language and escalation | `docs/ART_BIBLE.md` |
| Ambiguities and immutable story rules | `docs/CANON.md`, `docs/source/STORY.md` |
| Script/scene/autoload APIs and lifecycle | `docs/ARCHITECTURE.md` |
| Work queue and dependencies | `docs/TASKS.md` |
| Current shared decisions | `docs/DIRECTION.md` |
| Per-task implementation notes and handoff | `docs/state/<ID>.md` and `docs/HANDOFF.md` |

Follow existing scene/script APIs before adding new ones. Extend the Events bus where cross-system signals are required. Keep scripts statically typed and documented. Prefer small reusable systems and data-driven room/beat definitions over giant act scripts. Scenes should be runnable standalone when practical.

## 5. Build order: prove the pipeline before multiplying content

1. **Protect the source:** verify story/beat/world inputs and run contract validation.
2. **Playable foundation:** first-person movement, look, interaction ray, carry/hold, settings and accessibility.
3. **Visual baseline:** a representative test room with believable scale, PBR materials, practical lights, shadows, atmosphere, surface detail, and a clear performance budget.
4. **World-data pipeline:** room geometry, door graph, collision, state dressing, and route/connectivity checks.
5. **One quality-bar scene:** fully realise Act 3's dome and moon-eye moment. Validate the entire loop—approach, look, dialogue, Unreality response, cue, and player-triggered transition—before spreading the same level of detail to every act.
6. **Reusable atmosphere:** WrongnessDirector, audio spaces/occlusion, environmental storytelling, character presence, narration presenter and physical verbs.
7. **Complete the nine acts in order:** make every act navigable and beat-correct, then dress and polish it. Prioritise the mansion and other spaces where exploration time is highest.
8. **Integration:** play from start to finish, test all exits and save/load, profile performance, verify Windows export, and inspect visuals in a real window.

This sequence is a dependency guide, not permission to replace the story or skip world detail. A greybox is an intermediate validation tool, not a shippable art target.

## 6. Definition of done for each implementation task

A task is complete only when all applicable checks pass:
- **Story:** every implemented beat/action matches the source; no new story text was invented; the source file is unchanged.
- **World:** the player can physically reach required interactions; collision, doors, stairs and route graph agree with the plan; optional space feels intentional rather than empty.
- **Progression:** the beat is recorded once; cues are diegetic and noticeable but not overbearing; no transition fires until the player triggers it.
- **Unreality:** level changes are hidden, deterministic, persistent where intended, and visible/audible in the world; no player-facing number or meter exists.
- **Presentation:** lighting/materials/audio support the scene's emotional goal; placeholder assets are clearly marked and do not block standalone testing.
- **Accessibility/performance:** Reduced Motion is respected; settings work; no rapid flashing; representative frame-time and memory costs are documented.
- **Verification:** run the narrow test first, then `bash scripts/tools/run_tests.sh`; inspect Godot logs and the scene in a real window when available. Never claim a real-window check or test that was not performed.
- **Handoff:** list changed paths, public APIs, test commands/results, known limitations, and the next highest-value action.

If a check cannot be run in the current environment, report it as **not run**, not as a pass. Do not mark an unfinished visual placeholder as a finished art pass.

## 7. Asset and rendering standards

- Godot 4.3+ / GDScript. Windows 10 64-bit is the minimum target; Windows 11 is supported.
- Aim for a believable, high-detail 1080p experience at 60 fps on the documented target hardware. Preserve a lower-cost Compatibility-renderer path for weaker supported systems.
- Use real PBR texture sets, correct scale, sensible roughness/normal response, layered set dressing, decals/wear, and motivated lights. Keep external assets license-clean and recorded in `assets/LICENSES.md`.
- Spend detail budget where the camera can approach and where the story asks the player to look. Use LODs, occlusion, instancing, baked lighting and streaming where they protect frame time.
- Do not let a post-processing shader do the work of a convincing world. Geometry, light, material, composition, performance, and sound come first.
- Missing art must have an intentional fallback, so the project opens and tests without a complete asset library.

## 8. Agent operating loop

1. Read this file, then the relevant sections of VISION, CANON, ACTS, WORLD_BIBLE, ART_BIBLE and ARCHITECTURE. Inspect the current code and task handoffs before editing.
2. Pick one bounded unit of work with a visible result and explicit acceptance criteria. Avoid rebuilding an existing system.
3. Make changes in the existing repository structure. Preserve shared-file conventions unless the human explicitly overrides them.
4. Run relevant validation and tests; record exact results. Inspect the diff for accidental source/story/data changes.
5. Commit or hand off the actual files, not just a proposal. Summarise changed files, tests, limitations and next action.
6. If blocked by missing assets, use clearly marked placeholders and finish the data/scene contract instead of stalling. Ask the human only for a decision that cannot be inferred from canon or the current project.

## 9. Minimum human review gates

The human should see and approve:
- The first representative lighting/material room.
- Act 3's dome and eye in a real window.
- The mansion blockout and the key route through it.
- Any proposed new shock, explicit body-horror image, or change to the story's physical events.
- A complete beginning-to-end playthrough before calling the game finished.

Do not require art-reference input before beginning. Use restrained, cinematic realism as the default and record alternatives as optional proposals.
