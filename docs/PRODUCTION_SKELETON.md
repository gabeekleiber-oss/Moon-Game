# Production Skeleton: how the finished experience is assembled

This is the project-wide delivery map for agents. It adds execution detail to `BUILD_METHOD.md`; it does not replace canon, act beats, world data, or code APIs. Read it after the Start Here sequence in the README and before proposing a new system. It deliberately describes *contracts and evidence*, not a second design or a list of speculative features.

## 1. Authority and non-negotiable inputs

Use this precedence order when documents appear to overlap:

1. `docs/source/STORY.md` is immutable verbatim source text. It must remain byte-for-byte unchanged.
2. `docs/CANON.md` controls facts, ambiguity, permitted shocks, and adaptation boundaries.
3. `data/story/beats.json`, `docs/ACTS.md`, `data/world/`, and `docs/WORLD_BIBLE.md` control the October 12, 2026 beat and space contracts. Preserve them unless the human explicitly changes the story/world.
4. `docs/ARCHITECTURE.md` controls runtime APIs, scene lifecycle, and folder ownership.
5. `docs/BUILD_METHOD.md`, `docs/ART_BIBLE.md`, and this file control production practice and quality gates.
6. `docs/TASKS.md` is the single executable queue. It is script-owned; do not hand-edit it or create a shadow queue here.

No agent may solve a conflict by copying source data into a new format, building a `redesign/` tree, silently changing an existing beat, or inventing lore. Record a real ambiguity in the task checkpoint's `NOTES FOR DIRECTION`, implement only the inferable physical detail, and continue with bounded work.

## 2. Product shape and player promise

The finished game is one continuous-feeling first-person experience assembled from nine ordered acts. Each act is a richly dressed, navigable place with one story destination. The player may pause, look, explore optional space, and physically perform the actions named in the story. There is no score loop, combat loop, inventory menu, skill check, visible objective, health, stamina, timer, minimap, or player-facing sanity statistic.

The core loop is:

`arrive in a believable place -> orient through landmarks/sound/light -> freely explore -> notice a story affordance -> perform a forgiving physical action -> the world subtly changes -> choose the indicated exit`

Linear narrative and open-feeling exploration coexist through three constraints:

* Only the current act is available; the next act remains physically inaccessible until its prerequisites are complete.
* Within the current act, optional rooms, views, readable props, and alternate walking routes never create a dead end or imply a missing collectible.
* Completion changes the world and reveals an exit; it never moves the player, starts a loading transition, or puts an imperative objective on screen.

## 3. Runtime map and ownership boundaries

The project has five cooperating layers. Keep dependencies pointing down this list; an individual room should not reach into menus, and a shader should not decide a story beat.

| Layer | Owns | May depend on | Must not own |
|---|---|---|---|
| Source/data | Story text, beat IDs, room IDs, floor plans, dialogue payloads | Nothing at runtime | Alternate canon or duplicated world truth |
| Foundation | Input/settings, saves, Events, Acts, Unreality, Audio, Dialogue, Cutscene, PostFX | Source/data and Godot | Room-specific story logic |
| World kit | RoomBuilder, doors/locks, landmarks, props, Wrongness behaviours, spatial audio zones | Foundation and room data | Global progression rules |
| Act assembly | One act scene, beat wiring, state dressing, cue, exit | Foundation, world kit, data | New versions of shared systems |
| Presentation/verification | Materials, lights, ambience, accessibility variants, tests, capture, performance probes | All above | Declaring visual work verified without a real-window check |

### Required lifecycle

1. `main` starts the selected act through `Acts`; normal play selects Act 1 or saved progress.
2. `ActBase._ready()` establishes the act's hidden Unreality floor, presentation grade, beat tracker, and `act_started` event.
3. The act builds or streams its world state, then registers interactables, Wrongness participants, audio zones, and cue receivers using stable IDs.
4. An interaction calls the act's `beat("id")`; the beat tracker alone decides whether it records. Successful beats may set flags, trigger bounded audiovisual responses, and raise/spike Unreality.
5. The final beat emits completion, makes the diegetic unlock cue available, and unlocks—rather than enters—the next act.
6. The player uses the revealed physical exit. `Acts.transition_to()` owns fade/load/fade and leaves one act resident.
7. Save state records current act, completed beats/flags, and hidden Unreality state; it never records a score or a player-visible mental-health label.

### Stable identifier rule

Every authored thing that crosses a boundary needs a stable, human-readable ID: `act3.eye_argument`, `dome_moon`, `dining_table`, `cue_act4_bird_hall`, `audio.dome.wind`. Do not use node paths as durable data keys. IDs survive refactors, make deterministic wrongness possible, and let tests report useful failures.

## 4. System contracts to preserve

These contracts supplement, but do not override, `ARCHITECTURE.md`.

### Beat and progression contract

* Define a beat once in `data/story/beats.json`/`ACTS.md`; code wires that ID, it does not mint a near-duplicate.
* A beat is idempotent: repeated input cannot replay a permanent change or advance the tracker twice.
* Use prerequisites for genuine story dependencies. Where the source permits a set of observations in any order, use free-order beats and one explicit completion condition.
* A locked door, blocked path, or unavailable interaction must have an in-world reason and a quiet response. It must not say “objective incomplete.”
* A cue is a world state with a source, location, sensory channel, and associated exit. It remains available until the player uses the exit and is readable without requiring a subtitle or a HUD.

### Interaction and physical-action contract

All physical verbs build on the established Interactable/ray contract. Add a focused reusable action component only when at least two acts need it. A verb must specify:

| Field | Requirement |
|---|---|
| Approach | Reachable player position, facing tolerance, and camera readability |
| Input | One consistent contextual action; no timing bar or button mashing |
| Feedback | Hand/prop movement where useful, contact sound, material response, and one clear state change |
| Failure | Gentle, diegetic feedback; never a punishment loop |
| Completion | Exact beat ID/flag changed and whether it is repeatable |
| Comfort | Reduced Motion form, no rapid camera forcing, and clean cancellation/interrupt handling |

Use authored sequences for dangerous or complex actions such as the pot fall, fire, and flute dance. They should preserve first-person presence and player initiation without pretending to be free-form physics. Carrying should communicate mass through animation, audio, traversal limits, and camera-safe sway—not a visible weight meter.

### Unreality contract

Unreality is a hidden, deterministic presentation/progression signal, never a diagnosis and never UI. The sole writer is authored story code using the `Unreality` API. Systems may read ramps and stable wrongness selection, but must not invent their own sanity values.

For every new wrongness effect, document in its scene/script or checkpoint:

* stable `wrong_id`, threshold/ramp, and whether its change is persistent or a temporary spike;
* observed-state rule (normally change only off-screen);
* base-world fallback at level zero;
* Reduced Motion/flash-safe form;
* reset/save behavior and a deterministic test seam.

At least two non-camera channels should carry every major escalation: for example, a corridor length change plus an audio perspective shift, or a face held too long plus a narration timing defect. Post-processing is the final accent, never the only evidence that the world is wrong.

### Room and world-state contract

Geometry belongs to the canonical room data and RoomBuilder contract; hand dressing belongs to the matching world/act scene. Each room state must answer:

1. What is physically usable here?
2. What tells the player where they are without UI?
3. What life, wear, and wrongness layers are visible?
4. Which doors/paths are traversable for this act and why?
5. Which assets are placeholders, and what is their final-art replacement path?

Build the mansion once and use state dressing for night, dream, day, decay, and fire. Dream spaces are the documented exception, not permission to duplicate ordinary mansion geometry. A state change cannot invalidate a required route without supplying the authored route for that beat.

### Audio contract

Each playable room/road segment supplies room tone, ambience, interaction sounds, reverb/occlusion behavior, and a silence plan. Music is sparse and supports, rather than announces, progression. Dialogue remains readable as on-screen text with voice-blips; there is no assumed recorded voice acting.

Audio cues must have a spatial or clearly motivated source. A cue that guides an exit should be noticeable from the intended exploration area, degrade gracefully when subtitles are disabled (subtitles are always-on for narration, not a locator), and avoid becoming a looping alarm.

### Save/load and debug contract

Before implementation of a new persistent interaction, define its save representation: stable flag/beat ID, default, migration fallback, and restoration point. Reloading must not replay an irreversible shock unless the story state calls for it. Developer tools may expose act selection and Unreality values but must remain unavailable to the normal player flow.

## 5. Nine-act assembly scaffold

`docs/ACTS.md` is the canonical detailed beat list. The following is the build-facing checklist; it does not add beats or alter story facts.

| Act | Space and exploration promise | Hero staging / reusable proof | Player-chosen transition |
|---|---|---|---|
| 1 — Wisconsin | A tired, specific 1990s house and snowy yard; domestic navigation before rupture | TV, damp letter, finger shock, broom/phone/tank actions | Get into the loaded Taurus |
| 2 — Road | Headlight-limited driving with believable roadside landmarks and optional looking stops | Road-segment streaming, inn/fork/raccoon, dawn sound/light shift | Drive/arrive at the clearing |
| 3 — Dome | Exterior approach and mansion route make the dome a visible spatial promise | Moon-eye encounter proves dialogue, eye shader, cue, and dark-house handoff | Enter/descend into the opened house route |
| 4 — Dark rooms | Navigation by bird light, architecture, sound, and touch instead of UI | Lantern, carry Mary Sue, closet/cyclone sequence, observed wrongness | Use the dreamward route when revealed |
| 5 — Birthday | A compact dream topology that rewards looking while keeping a single readable path | Identical doors, kitchen replica, cake/face transformation | Follow the transformed forest route |
| 6 — Lake | A quiet traversable edge of water, canoe, and sightlines with room to listen | Canoe/fishing verbs, controlled dialogue staging, Clement's final line | Choose the return/rest transition |
| 7 — Morning | Daylight mansion route where the plan is legible and wrongness is deniable | Seven pillows, portraits, chandelier ducking, long dining composition | Take the physical notepad/route it reveals |
| 8 — Inventory | Enfilade vista and side observation without turning treasure into a collectible loop | Armour/bird/gold room dressing; physical note-taking; flea onset | Follow the east-wing/back-door cue |
| 9 — Melting | The mansion/exterior route is revisited under peak pressure, but remains navigable | Axe/chop, pot, stairs, fire, flute dance, bedroom/moving moon | No next act: final window image and controlled end state |

For every act, create and maintain an act card in its checkpoint or scene notes containing: entry state, reachable room IDs, required beats and free-order groups, exact verbatim-data dependencies, cue source, exit interaction, Unreality writes, shocks, audio zones, persistent flags, placeholder list, and test scene/test command. This is an implementation record, not a copy of the story.

## 6. Asset, graphics, and scene pipeline

### Asset intake

1. Check whether a suitable existing asset/fallback already exists.
2. Choose a license-clean asset or make a procedural/placeholder stand-in that keeps scenes runnable.
3. Record every external asset in `assets/LICENSES.md` before it is treated as production content.
4. Normalize naming, scale, import settings, material maps, collider/LOD needs, and intended rooms.
5. Place the asset in the established `assets/` category and reference it through a reusable scene/material where repeated.
6. Verify missing-asset behavior and document the exact placeholder marker.

Do not commit an unlicensed “temporary” production asset. Do not bake a single source texture into a new untracked folder. Hero props—the letter, CRT, broom, fish tank, moon/eye, bird lantern, pot, axe, flute—need a dedicated quality/interaction review because they receive close camera attention.

### Scene composition pass order

Build in this order so detail remains purposeful:

1. **Spatial truth:** dimensions, floor/ceiling, doors, collision, routes, landmark sightlines.
2. **Light truth:** time/state, practical sources, bake/probe plan, darkness and contrast.
3. **Material truth:** PBR response, scale, repeated-material breakup, wear/decals/dust.
4. **Life:** furniture, clutter, habits, sound emitters, narrative prop placement.
5. **Wrongness:** stable off-screen changes and authored shocks layered on the believable base.
6. **Optimization:** occlusion, LOD/instancing, streaming, shadow/light counts, texture residency.
7. **Capture:** real-window review at the representative player height and path.

No scene is “art complete” merely because it has props. Its close-view materials, lighting source logic, traversal, audio, and performance budget must be known.

### Graphics quality bar

The baseline is restrained cinematic realism: correct scale, motivated illumination, PBR response, nuanced roughness, layered surface age, readable silhouettes, and detailed near-field dressing. Unreal effects should reveal a violation of this baseline, not hide its absence. Keep a Compatibility fallback in mind from the start: optional volumetrics, expensive transparency, dense particles, and advanced post effects must be independently degradable.

## 7. Comfort, accessibility, and content safety

Accessibility is a system requirement, not a late UI pass. Every act must be playable with remappable controls, sensitivity and FOV adjustment, readable text, subtitles/narration, pause capability, and Reduced Motion. Reduced Motion removes/limits bob, roll, warp, camera shake, particle swarms, chromatic effects, and rapid flicker while retaining the beat through sound, light, still composition, or text pacing.

Before adding an effect, check: no strobing above three flashes per second; no unskippable prolonged camera motion; no critical information conveyed only by color or a faint sound; no interaction that requires rapid repeated presses; and no non-consensual surprise of an unapproved explicit image. The source's listed shocks remain the limit unless the human approves a change through direction notes.

## 8. Performance and technical quality plan

The target is 1080p/60 fps on the documented GTX 1660/RX 580-class target, with a lower-cost Compatibility path. This is a target, not a performance claim. Test on representative scenes rather than averaging an empty room.

| Budget area | Design response | Evidence to record |
|---|---|---|
| Draw calls/repeated detail | Instance repeated props; combine static dressing where sensible | Probe/capture on mansion and fire-clearing paths |
| Lighting/shadows | Bake interiors; retain only motivated dynamic shadows in view | Dynamic-light count and real-window visual check |
| Geometry | LOD repeated/high-cost pieces; stream wings/exterior | Visible-triangle/streaming observation where tooling permits |
| Textures/materials | 1–2K typical textures, mipmaps, shared materials | Memory/import settings and no missing-material errors |
| VFX | Fixed caps; degrade independently for compatibility/reduced motion | Particle cap and peak-scene capture |
| Loading | One act resident; preload exit destination/essential hero data when safe | Transition test with no blocking error or lost state |

S-12 is the authoritative performance/smoke task. Do not create another performance framework; add probes and cases through that task’s public contract when it exists.

## 9. QA ladder and acceptance criteria

Run the narrowest relevant validation first, then project validation. Current structural preflight is `python3 scripts/tools/validate_project_contract.py`; the suite command is `bash scripts/tools/run_tests.sh`. If Godot or a real display is unavailable, say **not run** and leave visual review explicitly open.

### Minimum acceptance for a system

* It has one owner folder and documented public API/signal behavior.
* It has a focused test or a justified manual test procedure.
* It cannot expose a score/health/objective/Unreality meter to the player.
* Its settings/Reduced Motion behavior is defined where motion, sound, or text is involved.
* It leaves the project runnable with missing production art clearly marked.

### Minimum acceptance for an act increment

* Protected source, beat JSON, and world data pass the contract checks unchanged unless the human explicitly authorized a data change.
* Every required current increment beat is reachable, fires once, and survives its intended save/load path.
* The cue is visible/audible in-world and the exit remains player-triggered.
* Required routes, collision, and traversal work from a normal player camera.
* New Unreality is deterministic, hidden, and comfort-safe.
* Audio sources are located/motivated; dialogue/narration remains readable.
* A real-window check is recorded or truthfully marked unverified.

### Release acceptance for the nine-act experience

* Clean start-to-finish play reaches the final moon-eye image in source order with no auto-transition.
* No canonical story facts, protected source bytes, beat IDs, or world IDs were accidentally changed.
* Every act has an understandable spatial cue and at least one intentional optional observation area.
* Settings persist, save/load restores a valid play state, and Windows 10 export opens with the selected quality fallback.
* No visible gameplay meters/objectives have returned; developer controls are not player-facing.
* M1/M2/vertical-slice and final representative scenes have human real-window review, accessibility review, and performance evidence.

## 10. Work packages and dependencies

Use the IDs in `TASKS.md`; the dependency map below explains sequencing without duplicating or changing their status.

```text
M1: S-01, S-02, S-03, S-04, S-05, S-09, S-12
                    |
M2:              S-06 ----> L-04/L-05/L-06 ----> Act 3 vertical slice (A-03)
                    |                  |                    |
                 S-07              S-08/S-10              review gate
                    |
World expansion: L-01/L-02/L-03/L-07/L-08/L-09 + S-13..S-16
                    |
Act assembly: A-01 -> A-02 -> A-03 -> A-04 -> A-05 -> A-06 -> A-07 -> A-08 -> A-09
                    |
Integration: Z-01 -> Z-02 -> S-17/export review
```

Parallel work is safe only when agents own different folders and agree first on shared API additions. Foundation API work precedes room/act work that consumes it. Avoid “implement every act at once”: prove one representative vertical slice (Act 3) against the quality bar, then reuse its systems and lessons.

## 11. Agent execution and handoff protocol

Before changing files:

1. Read the relevant canonical docs, architecture contract, latest handoff, and source passage for the act.
2. Inspect existing code/data/tests and the diff. Reuse rather than replace.
3. Name a bounded increment, owner paths, dependencies, acceptance checks, and any protected inputs.

During work:

* Make minimal append-oriented shared-file edits; do not reformat unrelated files.
* Keep public interfaces typed and documented. Prefer data-driven additions and small reusable components.
* Run a focused check after a focused edit. Do not wait until a large unreviewable batch exists.
* Preserve a runnable fallback. Mark incomplete art `# PLACEHOLDER` and connect it to the existing task ID.

At handoff, use this exact content (in the project’s established checkpoint/handoff process):

```text
Scope: <bounded outcome and task ID(s)>
Changed: <paths and why>
Contracts: <public APIs, signals, data IDs, save state added/changed>
Canon/data audit: STORY unchanged; beats/world <unchanged or authorized change>
Verification: <commands/manual checks and exact results>
Visual review: <real-window result or “unverified in a real window”>
Known limits: <placeholders, missing assets, risks>
Next: <single highest-value dependency-safe action>
NOTES FOR DIRECTION: <only decisions/ambiguities needing durable visibility>
```

Never call a task done because its document exists. A document task is done when it gives an implementer a non-conflicting action boundary; an art/system task is done only when the relevant QA evidence exists.

## 12. Risks and decisions that remain open

| Risk or question | Default now | Owner/review point |
|---|---|---|
| Photoreal faces may fall into uncanny-bad quality | Use the intentional unfinished-face fallback until a convincing CC0-based test passes | S-08 + human visual review |
| High-detail mansion exceeds budget | Streaming, baking, occlusion, LODs, and representative probes before multiplying dressing | S-01/S-05/S-06/S-12 |
| Missing licensed art stalls work | Use code-built, clearly marked fallbacks and record asset intake needs | S-02 + relevant location task |
| Player gets lost in dark/open spaces | Landmark, light, sound, and architectural wayfinding; test without objective UI | Every location/act review |
| Surreal effects become generic or tiring | Stable authored effects, sparse shocks, multiple non-camera channels, Reduced Motion | S-07 + act reviews |
| Driving/carrying physics expands scope | Forgiving authored interaction sequences; validate feel before general simulation | S-03/S-13/S-15 |
| Visual claims overstate headless evidence | Treat headless as logic-only; record real-window status separately | Every handoff |
| Story ambiguity pressures agents to invent explanation | Keep ambiguity; build physical evidence only; elevate a direction note if irreversible | CANON gate + human |

The only current creative decisions awaiting human input are the art references, the eventual face-pipeline choice, and any requested new shock or story/world alteration already identified in `docs/DIRECTION.md`. None block the foundation, world data contracts, or the Act 3 vertical slice.
