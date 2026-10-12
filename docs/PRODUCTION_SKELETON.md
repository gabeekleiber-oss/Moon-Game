# Production Skeleton: how the finished experience is assembled

This is the project-wide delivery map for agents. It adds execution detail to `BUILD_METHOD.md`; it does not replace canon, act beats, world data, or code APIs. Read it after the Start Here sequence in the README and before proposing a new system. It deliberately describes *contracts and evidence*, not a second design or a list of speculative features.

### Fast routing for future agents

| If you are about to… | Read first | Leave behind |
|---|---|---|
| Add/change a story action | CANON, source act passage, ACTS, beat data, Sections 4/8 | One canonical beat wiring, source audit, route/transition evidence |
| Build a room/route | WORLD_BIBLE, room JSON, ART_BIBLE, Sections 5/9 | Room card, playable route, landmark/light/audio plan, placeholder note |
| Add a shared system | ARCHITECTURE, TASKS/HANDOFF, Sections 3/4/14 | Small public contract, focused test/example, consumer boundary |
| Add a prop/material/asset | ART_BIBLE, asset rules, Sections 5/9 | License trace, fallback, scale/material/LOD decision, hero-prop card if applicable |
| Add a surreal effect | CANON, ART_BIBLE, Sections 4/7 | Stable wrong ID, observed rule, comfort mode, deterministic evidence |
| Implement dialogue/cutscene | Source passage, CANON, Sections 4/6 | Exact text data, trigger/control plan, readable/motion-safe presentation |
| Improve performance or export | ARCHITECTURE, ART_BIBLE, Sections 12/13/14 | Representative measurement or smoke result; no unverifiable claim |
| Hand off work | BUILD_METHOD, HANDOFF, Section 15 | Scope, API/data audit, tests, real-window status, limitation, next safe step |

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

### Expected act scene anatomy

An act is composition, not a god-object. Exact nodes will evolve, but this ownership shape should remain visible:

```text
ActNN (ActBase: act identity, beat wiring, cue/exit coordination)
├── WorldRoot (loaded room/set-piece scenes; collision/navigation/streaming boundaries)
│   ├── StateDressing (act/time-specific props, lights, material variants)
│   ├── Interactions (act-owned bindings to reusable Interactable/action components)
│   ├── Wrongness (registered behaviours; no private sanity model)
│   └── AudioZones (room tone, reverb/occlusion, authored cue sources)
├── StoryMoments (small authored sequences/camera anchors; no replacement world)
├── PlayerSpawn (validated transform and initial facing landmark)
└── DebugAnchors (development-only route/capture markers, excluded from player presentation)
```

The root coordinates story state; a room scene owns its physical construction/dressing; a reusable component owns its generic behavior; an autoload owns cross-act state. If a scene begins to own all four, split it at the smallest stable interface. Add nodes for a concrete purpose, not for speculative categories.

### State ownership guide

| State type | Owner | Example | Lifetime |
|---|---|---|---|
| Canonical content | Data/docs | Room ID, beat ID, source passage | Versioned source |
| Durable progress | Game/Acts/save model | Completed beat, unlocked act, taken letter | Save/load |
| Hidden progression | Unreality | Act floor, permanent rise, temporary spike | Save/load or scoped decay as documented |
| Spatial state | Room/act scene | A door is open, a prop has moved, a light is on | Current act; persisted only when story-relevant |
| Presentation state | Local component/material/audio | Flicker phase, subtitle reveal, particle lifetime | Moment/frame/scene |
| Developer state | Debug tools | Forced act/Unreality value, capture marker | Never player save/UI |

This table is a safeguard against two common failures: saving temporary effects as permanent story facts, and hiding a permanent story change inside a disposable scene instance.

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

### Dialogue, text, and narration contract

The source controls all quoted/verbatim material. Dialogue JSON is a delivery format, not an opportunity to modernize wording, correct spelling, add connective narration, or resolve an ambiguity. When a passage is needed, retrieve it from the immutable source with the established act tool, put the exact words in the existing data format, and cite the passage/act in the checkpoint. If a physical interaction needs a line that the source does not provide, communicate it with animation, sound, or an extremely short non-verbatim interaction response rather than presenting fabricated quotation.

Text presentation needs three explicit states:

| State | Use | Rules |
|---|---|---|
| Narration | Christopher's internal/source narration | Readable line length, deliberate verse layout, no speaker portrait needed |
| Speech | A named character or the moon speaks | Speaker identity through layout/voice-blip treatment, not a dialogue-wheel UI |
| Environmental text | Letter, notepad, sign, painting label, object-facing text | Exists physically in the world and has a readable close-view treatment |

Every authored text event states its trigger, interruption behavior, skip/advance behavior, voice-blip profile, subtitle/readability behavior, and its relationship to player control. An intense scene may reduce player control briefly only when the player has triggered a specific source-supported action; it must restore control predictably and safely.

### Cutscene and camera contract

The player initiates spectacle. A cutscene is allowed only when it improves an authored story event that cannot read as free movement: the finger shock, eye encounter, face change, key falls, and selected Act 9 actions are examples. A cutscene is not a substitute for building an explorable room or placing a physical interaction.

For every camera-directed moment, specify its entry trigger, exit/cancel behavior, player position on return, motion-reduced form, source-correct duration intent, and exactly which systems are frozen. Avoid forced head rotation, surprise rapid cuts, and a third-person camera that breaks first-person embodiment. Letterbox/fade is a punctuation mark, not an all-purpose loading cover.

### Events and shared-state contract

The Events bus is append-only and semantically named. A system emits a fact (`beat_completed`, `cue_revealed`, `door_opened`) rather than a command addressed to one unrelated listener. Shared autoload changes must include: signal signature, sender, expected listeners, ordering/lifetime assumptions, and a focused test or manual exercise route. No act may depend on listener execution order unless the event API explicitly guarantees it.

Flags represent durable, source-relevant facts—not temporary visual conditions. For example, a beat completion or door unlock may be a flag; a flickering light's current phase is local state. This distinction keeps saves clean and prevents stale visual bugs from becoming canon state.

## 5. Authoring records: the minimum paper trail for a giant project

The repository should contain enough structure that a new agent can continue a room, prop, or act without reverse-engineering another agent's intention. These records live in the task's checkpoint/state note unless an existing canonical data format already owns them. They are not alternate story data.

### Act card template

```text
Act: <number and source title>
Entry: <spawn, time/state, retained sound/image from prior act>
Playable envelope: <reachable room IDs; optional observation pockets; hard boundaries>
Landmarks: <three or more visual/audio anchors>
Required beats: <canonical IDs in tracker order>
Free-order group(s): <canonical IDs and completion condition, if any>
Verbs: <player-facing physical actions; shared system used>
Text/source: <act passage/data filenames; TODO_VERBATIM only where source absent>
Cue: <visible/audible source, discovery area, exit it points toward>
Exit: <interactable, player trigger, destination/load rule>
Unreality: <floor; permanent raises; spikes; stable wrong IDs>
Shock safety: <listed shock only; motion-reduced form; post-shock recovery>
Audio: <zones, signature sounds, music state, intentional silence>
Save: <flags and restoration behavior>
Art: <hero props, state dressing, placeholders/assets>
Checks: <unit/route/manual/real-window/performance evidence>
```

### Room card template

Every physical room/set-piece must be legible as a place before it becomes a horror space. Its room card therefore captures:

```text
ID/frame/state: <canonical room ID; mansion/ext/road/wi/dream; time-state>
Spatial contract: <footprint or set-piece bounds, entries/exits, collision, verticality>
Purpose: <story use and optional exploration value>
Landmark: <what the player recognizes from the threshold>
Lighting: <motivated sources, bake/dynamic plan, dark-path fallback>
Materials: <dominant surfaces, age/wear, hero close-view surfaces>
Dressing: <use layer, neglect layer, exactly placed story props>
Sound: <room tone, ambience, occlusion/reverb, triggered spots>
Wrongness: <base truth, IDs, thresholds, observed-state behavior>
Performance: <streaming boundary, repeaters, LOD/occlusion concern>
Access: <door/lock/cue behavior, Reduced Motion/readability equivalents>
Proof: <route test and player-height capture angle>
```

### Hero-prop card template

Use this for any object that is close-read, carried, or turns the story: letter, CRT, broom, phone, fish tank, Taurus, moon/eye, bird lantern, notepad, statues, axe, melting pot, flute, and fire.

| Aspect | Required decision |
|---|---|
| Canonical role | Exact source action/act and any immutable physical fact |
| Visual role | Silhouette, scale reference, material condition, close-view detail |
| Interaction | Reach, prompt, verb, animation/physics boundary, idempotent result |
| Audio | Pick-up/use/impact/loop/stop behavior and spatial source |
| State changes | Beat/flag, world response, save/load restoration |
| Wrongness | What remains real at zero and what changes at higher Unreality |
| Production | Asset source/license or placeholder, LOD/collider, test evidence |

### Asset manifest fields

`assets/LICENSES.md` remains the license authority. When the asset pipeline lands, every production asset should be traceable through the following fields, whether in its import record or checkpoint: asset ID, source URL, license, attribution requirement, original filename, import location, type, scale/unit, texture maps, material owner, LOD/collider status, room/prop consumers, placeholder replaced, and review status. The goal is to make removal or replacement safe without hunting through scenes.

## 6. First-person player model and action language

The player is Christopher, present as a body in a place—not a floating inspection camera. The baseline is deliberate, grounded walking with readable eye height, collision, step-up/stair behavior, crouch/duck capability, hands/forearms where useful, and a stable camera. This is not a simulation of exhaustion or combat.

### Action families

| Family | Examples in scope | Implementation rule |
|---|---|---|
| Look/listen/approach | Study the moon, portraits, lake, family, doorway | Let composition, outline, sound, and proximity carry discovery; never turn it into a spotting minigame |
| Use/open | Doors, switch, letter, notepad, car, bed | One contextual action with clear physical state and quiet failure response |
| Take/carry/place | Mary Sue, axe, pot, bags, physical notepad | Use shared carry state, authored anchor points, and traversal-safe collision |
| Strike/throw | Broom/TV, phone/tank, chopping, match/fire | Forgiving authored contact window; story result is deterministic, not score-based |
| Traverse | Drive, stairs, porch, canoe, forest, dance circuit | Prioritize camera comfort, route clarity, and story staging over high-fidelity vehicle/physics simulation |
| Sit/rest/transition | Car, canoe, bed, final window | Player confirms the act change; return/cancel behavior stays clear until committed |

### Player state rules

Only use states that have a visual/audible reason: free movement, constrained/carrying, contextual action, authored moment, dialogue reading, pause, and transition. Each state has one owner, a defined exit, no invisible input traps, and safe handling for pause/settings. Never stack a hidden action lock and a dialogue lock so the player loses control without a clear reason.

The player should not be able to sprint past a critical scene by accident, but that does not justify invisible walls in ordinary exploration. Use composition, path width, prop placement, sound, believable locked doors, weather/terrain, and soft contextual slowdown around precision interactions. If a boundary must be hard, make its world reason obvious.

### Interaction readability at player height

Before calling an interaction complete, inspect it from the normal camera, standing and crouched where relevant, at normal approach speed and in its intended lighting state. Validate prompt legibility, reach distance, occlusion by hands/held props, collision, outline restraint, and one-handed accessibility. The interaction should not require the player to hunt for a one-pixel hotspot; generous authored volumes are preferable to a visible target UI.

## 7. Cue, transition, and wayfinding design

Transitions are a promise that the player recognizes before using. Every act cue combines a **source**, **signal**, **path**, and **threshold**:

```text
beat completion -> source changes in the current world -> player notices signal
                -> signal makes a path/exit newly meaningful -> player uses threshold
                -> fade/load/fade preserves emotional continuity
```

The source is tangible: a door opens, moonlight settles somewhere, a car waits, a sound travels from a room, a stair is now lit, the bed is visibly available. The signal must be noticeable without being an alarm. The path must be traversable without a UI arrow. The threshold must require an intentional final use/entry action.

### Cue review questions

* Can a player who has been exploring the least convenient optional room still rediscover the cue by ordinary movement or sound?
* Does the cue read in the intended lighting/accessibility modes?
* Is the exit’s relationship to the cue spatially plausible?
* If the player delays, does the cue remain meaningful rather than looping or escalating into noise?
* Does a save/load after completion restore the cue and exit coherently?
* Does the transition preserve source order without accidentally beginning the next beat?

### Wayfinding palette

Use one dominant landmark plus two supporting signals per exploration area. Examples are architectural (dome, grand stair, twenty-seat table), material (red carpet/gold statues), light (lantern/moon/fire), sound (kitchen life, grackles, water), and silhouette (shed/woodpile/tree line). Do not use painted arrows, objective icons, glowing collectibles, or “wrong way” messages. In dark scenes, the safe path may be dim, but its contrast and sound should still be intentional.

## 8. Nine-act assembly scaffold

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

## 9. Asset, graphics, and scene pipeline

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

### Visual production pass checklist

Treat a location as a sequence of accountable passes, not one vague “art pass.” A later pass may discover a need to revisit an earlier one, but it must not skip it.

| Pass | Questions to answer | Evidence/artifact |
|---|---|---|
| 0. Reference and canon | What is literally required? What must remain ambiguous? What cannot depict a real likeness? | Act/room/hero-prop card with canonical source references |
| 1. Blocking | Can the player walk, turn, duck, carry, see the exit, and understand scale? | Playable blockout + route result |
| 2. Composition | What is seen on entry, at story action, and when looking back? Which landmark dominates? | Named player-height capture anchors |
| 3. Light | What visible source motivates each important light? What does darkness conceal/reveal? | State lighting plan and bake/dynamic note |
| 4. Material | Does each near surface have plausible scale, roughness, normal response, wear, and breakup? | Material list and close-view check |
| 5. Life/dressing | What was this place used for? What has been neglected? Which props support the current action? | Dressing checklist tied to room card |
| 6. Acoustics | What is heard standing still, at entries, near props, and after a door closes? | Zone/cue list and walk route |
| 7. Wrongness | What is initially true, what changes off-screen, and what remains after looking away? | Stable wrong IDs + level-zero/peak capture plan |
| 8. Comfort | Does reduced motion keep the meaning? Is text/cue legible? Can player control return safely? | Accessibility note and manual exercise route |
| 9. Optimization | What repeats, streams, occludes, bakes, or degrades? | Budget/probe note, not a guess |
| 10. Review | What specifically needs a human real-window judgment? | Capture list and explicit unverified items |

### Definition of ready for a scene build

An agent may start a room/scene implementation once it knows the canonical room/act IDs, state/time, physical route purpose, required interactions, target systems it consumes, asset fallback plan, and acceptance check. If any of these are absent, create only the smallest discovery/prototype needed to answer them; do not commit a detailed scene based on invented assumptions.

### Definition of ready for a hero moment

A hero moment is ready to build only when its exact source portion, player trigger, camera/control boundary, spatial location, props/characters, sound plan, Unreality write, motion-reduced form, and aftermath/cue are identified. This prevents an impressive isolated cinematic from contradicting the world around it.

## 10. Audio and atmospheric staging

Sound is part of level geometry. A room is not complete when it is silent except for interactions; it needs an authored acoustic identity that helps the player believe and navigate it. Start with silence/room tone, then place ambience and spot sounds, then decide whether music should enter at all.

### Audio layer plan

| Layer | Question for authoring | Examples |
|---|---|---|
| Silence | What should the player notice because sound is absent? | Pre-shock hush, empty dome, lake pause |
| Room tone | What persists while the player is still? | House settling, electrical hum, distant wind |
| Exterior/biome ambience | What gives direction and weather/time? | Cicadas, grackles, snow-muted street, forest wall |
| Object spots | Which sounds make a prop tactile and spatial? | CRT, floorboard, letter paper, door latch, kettle, axe impact |
| Character/text | How do typed words gain presence without voice acting? | Character-specific voice blips, pauses, controlled doubled timing |
| Music | What emotional current is present without telling the player how to feel? | Moon Waltz fragments, music-box/pump-organ color, rare cue states |
| Unreality | What subtly violates the previous acoustic truth? | Impossible distance, detune, dropout, wrong reverb, delayed echo |

Do not fill silence automatically. Mix from the player’s likely camera positions, through doors and around corners, not only from an editor listener. A sound that functions as wayfinding needs an authored attenuation/occlusion test and a fallback visual signal. A sound that functions as horror must be allowed to end; endless whisper loops become ambience noise rather than dread.

### Audio handoff fields

For each authored zone/cue, record: zone/clip ID; state/act; source position or non-spatial rationale; loop/one-shot behavior; bus/reverb/occlusion intent; entry/exit fade; Unreality behavior; Reduced Motion or comfort consideration; asset/license status; and test route. This keeps a later mix pass from having to discover why a sound exists.

## 11. Comfort, accessibility, and content safety

Accessibility is a system requirement, not a late UI pass. Every act must be playable with remappable controls, sensitivity and FOV adjustment, readable text, subtitles/narration, pause capability, and Reduced Motion. Reduced Motion removes/limits bob, roll, warp, camera shake, particle swarms, chromatic effects, and rapid flicker while retaining the beat through sound, light, still composition, or text pacing.

Before adding an effect, check: no strobing above three flashes per second; no unskippable prolonged camera motion; no critical information conveyed only by color or a faint sound; no interaction that requires rapid repeated presses; and no non-consensual surprise of an unapproved explicit image. The source's listed shocks remain the limit unless the human approves a change through direction notes.

## 12. Performance and technical quality plan

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

## 13. QA ladder and acceptance criteria

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

### Test matrix: what evidence answers which failure

| Check type | Answers | Does not prove | Typical owner |
|---|---|---|---|
| Contract validator | Protected source/data IDs and required scaffold are intact | Scene feel, Godot parse/runtime behavior, performance | Any agent before handoff |
| Focused unit test | One deterministic model/API behaves at boundaries | Scene integration or visual quality | System owner |
| Scene smoke test | Scene loads without parse/missing-resource errors | Correct route, lighting, or storytelling | Scene/act owner |
| Route-walker/manual route | Doors, collision, beat order, cue, and exit work in player order | Final art quality or frame budget | World/act owner |
| Save/load check | Persistent beats/flags/exit restore coherently | Every other act or first-run UX | Act/foundation owner |
| Screenshot/capture strip | Composition regressions at named camera positions | Real GPU performance or subjective atmosphere | S-12 + scene owner |
| Real-window review | Readability, darkness, motion comfort, atmosphere, and material response | Broad compatibility without target hardware | Human reviewer |
| Performance probe | Cost on a representative route/mode | Artistic quality or all target hardware | S-12 + platform owner |
| Export smoke | Packaging/startup/input/save behavior on Windows | The whole quality bar | S-17 + integration owner |

When a failure appears, fix it at the lowest appropriate layer. A route issue belongs in geometry/door data before it becomes an act-script workaround; a repeated wrongness issue belongs in its reusable behavior before each room gets a separate exception.

## 14. Work packages and dependencies

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

### Milestones and their exit evidence

These milestones describe delivery shape; task IDs/status remain only in `TASKS.md`.

| Milestone | Delivers | Must demonstrate before advancing | Should deliberately defer |
|---|---|---|---|
| M0 — Guardrails | Protected source/data checks, canonical doc map, task/handoff conventions | Validator passes; no parallel project; a new agent can locate authority and current work | New content, speculative assets, art polish |
| M1 — Foundation | Player/interaction baseline, settings, text/audio hooks, data/world builder seam, visual/performance test seams | A small test space supports movement, one interaction, a beat, hidden Unreality, accessible settings, and automated checks | Building all acts or final characters |
| M2 — Mansion spatial proof | Correct-scale mansion/exterior blockout, room graph, streaming/door patterns, day/night dressing seam | Required Act 3/4/7/8/9 routes are physically walkable; landmark navigation works without UI | Final furniture density in every room |
| M3 — Act 3 vertical slice | Exterior arrival through dome/eye, one complete cue/exit, moon/eye and dialogue quality path | Full enter–act–cue–player-exit loop with save/load, comfort path, real-window review, and a representative budget capture | Copying the slice into every act without learning from it |
| M4 — World/verb library | Reusable carry, doors, wrongness, audio zones, driving/canoe/fire supports as needed; all major location blockouts | Each system has a bounded API, fallback, and example scene; every act’s route has a physical home | Excessive bespoke mechanics for one beat |
| M5 — Nine-act playable spine | Source-order beats, transitions, dialogue data, routes, cues, and placeholders across all nine acts | A clean start-to-finish player path reaches the end with no auto-advance or canonical drift | Calling placeholder art final |
| M6 — Fidelity passes | Set dressing, materials, lighting, sound, characters, wrongness, performance/accessibility passes | Representative human reviews and performance/export evidence; issue triage is closed or explicitly accepted | New plot, new mechanics, unapproved shocks |

### Recommended bounded increment size

One agent increment should normally end with a single observable proof: a valid room route, one portable behavior, one complete cue, one hero prop interaction, one act beat group, one capture/probe harness, or one compatibility mode. If an increment simultaneously changes the world schema, multiple autoloads, a room kit, dialogue format, and an act, split it at the public seam first. The exception is a deliberately coordinated vertical-slice integration, whose checkpoint must enumerate each seam and rollback/fallback plan.

### System charter map

The queue names the work; this map says what a future implementer must leave behind. It is intentionally a contract-level outline, not replacement task status.

| Queue area | Minimum durable output | Example proof before consumers rely on it |
|---|---|---|
| S-01 lighting baseline | Environment presets, practical-light helpers, a test room, documented bake/dynamic choices and quality tiers | Same room reads in intended day/night state with named sources and a real-window capture request |
| S-02 asset/material pipeline | License manifest process, catalog/fallback path, PBR loader/material conventions, import/check tooling | One licensed hero/repeated asset plus a missing-asset fallback renders without broken references |
| S-03 player/carry | Grounded controller, duck/stair/footstep behavior, hands, carry state and authored anchors | Player picks up/sets down one representative object, crosses a stair, and toggles Reduced Motion safely |
| S-04 narration presenter | Narration/speech/environmental text styles, exact text plumbing, pacing/voice-blips, accessibility fallback | A verse, a line of dialogue, and an object reading each render from data without invented copy |
| S-05 RoomBuilder | Canonical schema reader, geometry/door/collision/navigation output, route/data validation | One mansion room builds from data and matches its footprint/door graph in a route test |
| S-06 mansion blockout | Main block, exterior anchors, streaming pieces, every required route landmarked | Act 3/4/7/8/9 routes traverse at correct scale with no temporary teleport dependency |
| S-07 WrongnessDirector | Registration API, observed-state utility, deterministic behavior library, tests | One off-screen prop change and one corridor/door behavior restore correctly after save/load |
| S-08 character pipeline | Body/face fallback, material/LOD conventions, character placement/presence contract | One character reads at intended range without real-person likeness or unacceptable face quality |
| S-09 audio design layer | Zone/reverb/occlusion helpers, ambience routing, Unreality mix hooks | A player can locate a room-bound cue by sound and it behaves through a closed door |
| S-10 moon/eye | Dome/window variants, material/eye control, Unreality and comfort path | Eye encounter works from normal camera in Act 3 vertical slice and remains readable in compatibility mode |
| S-11 title/save | Start/continue/credits shell, stable save payload/migration policy | New game, resume, act select debug, and invalid/older save fallback are testable |
| S-12 performance/regression | Probe scene, smoke/load route, capture naming, performance evidence format | Named representative route produces a repeatable report/capture with clear pass/not-run status |
| S-13 vehicle/road | Taurus control boundary, segment assembly, road-state hooks | Drive across a fork/inn/hill sequence without soft-locking or requiring arcade score logic |
| S-14 fire/atmosphere VFX | Budgeted fire/smoke/embers/dust/shaft kits and comfort/quality tiers | Fire-clearing scene holds caps and preserves the scene when high-cost effects are disabled |
| S-15 physical verbs | Small contextual action library with sound/animation/beat hooks | At least two verbs from different acts reuse the same contract and remain idempotent |
| S-16 birds | Bird/nest/lantern/behaviour kit with scale and LOD rules | Lantern/bird state reads from normal player distance without runaway cost or generic flock clutter |
| S-17 Windows packaging | Export preset, quality selection, startup/settings smoke procedure | Fresh Windows launch reaches a playable start with a documented fallback renderer path |

Location packages must leave an explorable spatial envelope plus cards for every room/set-piece; they do not need final art before acts begin. Act packages must consume existing shared systems and location space; they must not rebuild a private player, door, text, audio, or Unreality implementation. Integration packages own end-to-end regressions and may request small fixes, but should not hide major architecture rewrites inside a polish pass.

### Collaboration and merge discipline

* Inspect the active diff and `HANDOFF.md` before editing. Treat uncommitted work as another agent's work unless it is clearly yours.
* Reserve ownership by folder/contract in the checkpoint; do not edit shared autoloads or `project.godot` opportunistically.
* For a shared API change, first add/confirm the contract, then make the smallest append-only implementation, then update one consumer and one test/example. Do not update every consumer speculatively.
* Keep data migrations additive and reversible. A schema change needs a validator update, existing-data compatibility plan, and exact list of consumers.
* Rebase/merge conflicts are resolved in favor of source/canon and established public APIs unless the human chose a new direction. Never “solve” a conflict by deleting another agent's infrastructure.
* A handoff that leaves a partial system must say how to run it, what not to build on yet, and the first safe continuation step.

## 15. Agent execution and handoff protocol

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

## 16. Risks and decisions that remain open

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
