# ROADMAP: what to build, in what order, and what "done" means

Derived from the real dependency graph in `docs/TASKS.md` (`start.sh` claims the next TODO whose `needs` are DONE, in file order, so these waves happen naturally). Update this file when the plan changes; do NOT edit TASKS.md by hand.

## The five waves (task layers)
| Wave | Tasks (all can run in parallel inside a wave) | What exists at the end |
|---|---|---|
| 0 Foundations | S-01 lighting, S-02 assets/materials, S-03 player+carry, S-04 narration text, S-09 audio layer, S-12 perf/smoke, S-14 fire/smoke VFX | A walkable, well-lit, well-heard empty test room with hands, carry, on-screen text and a frame-time probe |
| 1 Kits | S-05 RoomBuilder, S-08 characters, S-10 moon+eye, S-13 Taurus/driving, S-15 physical verbs, S-16 birds, S-17 Windows export, L-03 mansion exterior, L-08 lake | Any `data/world` room can be generated; people, the moon, car, birds, verbs and two finished places exist |
| 2 Places | S-06 mansion blockout, S-07 WrongnessDirector, S-11 title/save, L-01 Wisconsin house, L-02 road, L-09 fire clearing, A-06 (Act 6) | Wisconsin house and road dressed; the whole mansion walkable greybox; wrongness runs; Act 6 (lake) is playable end to end |
| 3 Mansion + first acts | L-04..L-07 mansion floors/wings/dream, A-01, A-02 | **Vertical slice**: Acts 1 and 2 playable from the living room to the dawn arrival |
| 4 Remaining acts | A-03, A-04, A-05, A-07, A-08, A-09 | The whole story playable in order |
| 5-6 | Z-01 integration, Z-02 polish | Ship candidate |

## Milestones (what the human should be able to *play*)
* **M0 "the room"** (end of wave 0 + S-05): one real room, lit, with a player, hands, an interactable and a line of narration. Proves the look.
* **M1 "the first ten minutes"** (A-01): Wisconsin living room to the loaded Taurus: finger shock, letter, broom, TV twice, phone, tank, the car. This is the **vertical slice target**: everything the game needs (verbs, text, wrongness, light, sound, a shock, a cue and a player-triggered exit) exists here in miniature. Build it first and make it excellent before widening.
* **M2 "the drive"** (A-02) then **M3 "the house"** (A-03/A-04): the moon with an eye; the dark Bird Hall.
* **M4 "the dream"** (A-05/A-06), **M5 "the day"** (A-07/A-08), **M6 "the fire"** (A-09), then Z-01/Z-02.

## Priorities inside wave 0 (if only some run at once)
S-01 and S-02 first (everything is judged on look), then S-03 and S-04 (without them no act can be tested), then S-09. S-12 early keeps budgets honest. S-14 can wait until Act 9 nears.

## Parallel lanes (so five agents never collide)
* **Look:** S-01, S-02, S-10, S-14 (shaders, lights, VFX; touch `scenes/fx`, `assets/`).
* **World:** S-05, S-06, S-07, L-xx (touch `data/world`, `scenes/world`, per-location folders).
* **People and verbs:** S-03, S-08, S-15, S-16 (touch `scenes/player`, `scenes/characters`, `scenes/verbs`, `scenes/birds`).
* **Words and sound:** S-04, S-09, A-xx dialogue data (touch `scenes/dialogue`, `scenes/audio`, `data/dialogue`).
* **Pipeline:** S-11, S-12, S-17, Z-xx.
Shared files (`events.gd`, `game.gd`, `acts.gd`, `unreality.gd`, `project.godot`) take minimal appends only.

## Definition of done: the status fields in every `data/world/<space>.json`
Each room has `status: {blockout, dressed, lit, wrongness, audio}` with values `todo | wip | done`. A value is `done` only when:
* **blockout**: generated from the data by RoomBuilder at correct scale; every door in the door graph passes the route walker; collision and navigation work; no gaps at corners.
* **dressed**: the three layers in `notes` (use, wear, wrong) are visibly present; at least 25 distinct props for a room of 20 m2 (scale up/down); no repeated prop more than 3 times in view except deliberate sets (seats, candles); materials come from the PBR library, not flat colour.
* **lit**: every light is motivated (lamp, window, TV, candle, moon, fire); the room reads correctly in every state it has (`night`/`day`/`fire`); no light leaks; shadow-casting lights <= 2 per view; bake exists for interiors.
* **wrongness**: every instance in `data/wrongness/catalog.json` for this space is implemented, registered with its id, and respects its observed rule and Reduced Motion fallback.
* **audio**: room tone, a reverb zone, footstep surface, and at least one point source with a purpose (a clock, a hum, a bird); wayfinding cues for the act where this room is a route.
**Verification:** a screenshot from a real window or a human play note, not only headless tests (`docs/ART_BIBLE.md` "Verification"). Agents cannot see a real window: mark `wip` and ask the human via NOTES FOR DIRECTION.

## Definition of done: an act (A-xx)
All its beats complete in order through `ActBase.beat(...)`; every beat's verb works with its forgiving fallback; narration/dialogue come from `data/dialogue` lines anchored to `data/story/story_map.json` ids with no `TODO_VERBATIM`; the unlock cue fires and the exit is player-triggered; Unreality stays within [floor, next floor); the act runs standalone and via `-- --act=N`; skip/Reduced Motion paths set the same end state; the room checklist above is met for every room it needs, or the gaps are listed in the act's HANDOFF NOTE.

## Known gaps in the bones (for the next bones-pass or the next agent to fix)
* Beat id `bed` exists in both Act 7 and Act 9: always qualify as `actN.beat` (`ActBase` should key by act+id).
* Room files still have `states.*.notes: "TODO"` (84 TODOs): lighting notes per state are the first thing the S-01 agent should fill for the rooms it tests.
* No per-space audio sheet yet (S-09 should add `data/audio/spaces.json` from the room `notes.use`).
* No `docs/source/refs/` visual references yet (human); until then follow ART_BIBLE words only.
* Characters: real-person likenesses are forbidden (VISION); the TV actor, the Beatles and the pope are silhouettes/stylised.
