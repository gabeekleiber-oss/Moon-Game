# WORLD BIBLE: the map

World building and map design are the **top priority** of this project. Build places like an architect, then like a set dresser, then like a haunter. This file is the plan. A task that changes the plan changes THIS FILE FIRST (and says so in NOTES FOR DIRECTION).

## Principles
1. **Plan before geometry.** Every space has a floor plan with coordinates and a door graph (below). The plan must make every route in the story physically work, *including the routes the story makes impossible on purpose*.
2. **Real-life accuracy.** Real dimensions, real proportions, real construction. Rooms have structure (studs, trim, switches, vents, outlets), use (what happened here every day) and wear. The Wisconsin house is a believable 1990s American home; the Gronfiser house is a believable early-1900s Texas oak-and-red-brick mansion that someone has kept grand and mostly ignored.
3. **Every space has three layers:** *use* (the life that was lived here: clutter, objects, habits), *neglect/wear* (dust, stains, repairs), and *wrongness* (the unreality behaviours it will show; see ART_BIBLE). Write all three in the room's data file `notes`.
4. **Wayfinding by landmarks, never UI.** The player must be able to find their way by what they see and hear: the dome, the lantern, the great staircase, the dining table, the smell-of-eggs sound from the kitchen. Dark acts guide by light and sound.
5. **Add no lore.** Describe what is physically there; never invent backstory the story doesn't contain (CANON).
6. **One house, several states.** The mansion is built once (geometry from the plan) and *dressed* per state: `NIGHT` (Acts 3-4, pitch dark), `DREAM` (Act 5, off-plan spaces), `DAY` (Act 7-8), `DECAY` (east wing, always), `FIRE` (Act 9 night). Unreality bends it further at runtime; it never needs a second building.
7. **Streaming:** the exterior and each wing are separate scenes loaded on approach; interiors use baked lighting and occlusion. A single room must never exceed ~250k visible triangles.

## Scale and coordinates
Metres. **+X east, +Z south (towards the front door), +Y up.** The mansion origin `(0,0,0)` is the centre of the main block's footprint at ground level. Ground floor level `y=0`, ceiling 4.4 m (double-height halls 9.4 m). Upper floor `y=+5.0`, ceiling 4.2 m. Dome room `y=+10.0`. Walls 0.30 m (exterior 0.45 m). Interior door 1.0 x 2.1 m, double door 1.8 x 2.4 m, window sill 0.9 m, skirting 0.15 m, stairs rise 0.18 / run 0.28 m, handrail 0.95 m, eye height 1.65 m. One player is 0.6 m wide, 1.8 m tall; the narrowest passage is 0.9 m.

## Room data format (`data/world/<room_id>.json`)
```json
{"id": "dining_room", "name": "Dining Room", "level": 0, "footprint": [[6,0],[23,0],[23,17],[6,17]],
 "ceiling": 4.4, "floor": "oak_parquet", "walls": "plaster_cream_wainscot",
 "doors": [{"id": "to_foyer", "to": "foyer", "wall": "W", "offset": 10.0, "width": 1.8, "locked_until": "act3.hallway"}],
 "windows": [{"wall": "S", "offset": 6.0, "width": 1.4, "height": 2.2}],
 "states": {"night": {"lights": []}, "day": {"lights": ["window_south"]}},
 "props": [{"kind": "table_20_seat", "pos": [14.5, 0, 8.5], "rot": 0, "wrong_id": "dining_table"}],
 "notes": {"use": "...", "wear": "...", "wrong": "..."}}
```
`footprint` is clockwise `[x,z]` in the mansion's coordinates. `locked_until` is a beat id from `docs/ACTS.md` (`actN.beat`). `wrong_id` registers a prop with the WrongnessDirector. The RoomBuilder task (`S-05`) generates walls, floor, ceiling, doors, windows and trim from this; artists/agents then dress each room by hand.

## The mansion (main block 46 m x 34 m, front door on the SOUTH face at (0,+17))
Oak frame and red brick, many tall windows, chimneys galore (eight), a glass dome on the roof over the stair hall. Built on a grassy clearing; a covered front porch with six steps.

### Ground floor (y = 0)
| ID | Room | Footprint (x0,z0)-(x1,z1) | Notes |
|---|---|---|---|
| G1 | **Foyer** | (-6,3)-(6,17) | double height; front door (0,17); west double doors to Bird Hall (-6,10); east double doors to Dining (6,10); opens north into the Stair Hall. A chandelier hangs low. Coat stand, umbrella urn, runner rug. |
| G2 | **Stair Hall** | (-6,-17)-(6,3) | double height; the **grand switchback staircase** rises north to the upper balcony; chandeliers hang low enough to duck. West door to G4 at (-6,-8); east door to Kitchen at (6,-8); a rear service door (0,-17). |
| G3 | **Bird Hall** | (-23,-5)-(-6,17) | 6.0 m ceiling; **dirt floor with rugs laid over it**; the **twelve-arm bird-nest lantern** hangs at (-14.5, 4.2, 6); piles of sticks and worms; the light switch is by the east door. West windows high and small. |
| G4 | **West service rooms** | (-23,-17)-(-6,-5) | pantry, laundry, boot room, and the **west back stair** (up to U5). Plain, cold, practical. |
| G5 | **Dining Room** | (6,0)-(23,17) | the **twenty-seat table** (11 m long, E-W; head at the west end near the foyer door, Frank at the far east end, "eighteen seats" away), sideboard with nine dining sets, display case with the French flute, a bar cart (whiskey), big south windows. Double doors to Foyer (6,10) and to Kitchen (14,0). |
| G6 | **Kitchen** | (6,-17)-(23,0) | a working mansion kitchen: range, long prep table, copper, a scullery. Door to Stair Hall (6,-8) and Dining (14,0). A **narrow door at (22.5,-12), "not on the plan"**, opens onto a short back stair that rises into the Military Gallery (U6). |
| G7 | **East Wing (ground)** | (23,-9)-(41,9) | a billiard room and storage; unlit, dusty, shuttered. Separate wing scene. |

### Upper floor (y = +5.0)
| ID | Room | Footprint | Notes |
|---|---|---|---|
| U1 | **Upper balcony / gallery** | rings the stair hall void (-6,-17)-(6,3) and the foyer void (-6,3)-(6,17) | a gallery around the double-height halls. The **north balcony** (z=-16) has several doors, **all locked but one**: the dome stair. |
| U2 | **Portrait Hall** | west segment (-23,13)-(-6,17), east segment (6,13)-(23,17), joined by a **bridge across the foyer void (z 13..17)** | windows all along the south (front) wall; paintings of the Gronfiser's exploits on the north wall: **the pope licking a golden boot; the Beatles with the Gronfiser's signature trombone, a crowd of 300,000**. Chandeliers hang low; the staircase down is at the north. |
| U3 | **Master bedroom** | (-23,3)-(-6,13) | an enormous bed; **seven pillows with the Gronfiser's seal**; a dresser, a jewellery box (the necklace), tall windows. Christopher wakes here in Act 7 and collapses here in Act 9. |
| U4 | **Mary Sue's room / Frank's room** | (-23,-6)-(-14,3) / (-14,-6)-(-6,3) | Frank's bed "you can lay on your tummy and not fall off". |
| U5 | **Closet suite** | (-23,-17)-(-6,-6) | a run of wardrobes and linen rooms; the back stair arrives here; **a closet whose clothes never end** (Act 4). |
| U6 | **Military Gallery** | (6,-17)-(23,-7) | rows of armour and family crests, each suit holding a sword, a mace, a bayonet, a gun. NE corner: the back stair from the kitchen. |
| U7 | **Bird Statue Room** | (6,-7)-(23,3) | silver, gold and bronze bird statues on windowsills, the loveseat, each blade of the ceiling fan, and protruding from the walls. |
| U8 | **Gold Statue Room** | (6,3)-(23,13) | **red carpet, black walls**; gold statues: Joshua Primo (8 ft, elephant staff), Crumpis (8 ft, baboon), Crumpalump (8 ft, tiger), **Curt (3 ft, loon)**. |
| U9 | **East Wing (upper)** | (23,-9)-(41,9) | **cobwebs, tapestry tears, decay**; the great painted-elephant **melting pot** in a corner. Reached from U7 (a stuck door at (23,-2)) and U8 (23,8). |
| U10 | **Dome tower** | circular, radius 8, centre (0,-6), floor `y=+10.0` | reached by a straight stair from the north balcony. A **giant glass dome** (apex y=18); the moon sits in it, milky and bright. The cleanest room in the house. |

The Military Gallery, Bird Statue Room and Gold Statue Room form a straight **enfilade** along x=14.5 (doors aligned, one long sightline of statues: the signature vista of Act 8).

### Door graph for the story's routes (all must work)
* **Act 3:** drive up the path -> front steps -> Foyer. West and east doors locked; the way north opens -> Stair Hall -> grand stair -> north balcony (more locked doors, one open) -> dome stair -> Dome.
* **Act 4 (dark):** Dome -> down -> Stair Hall -> Foyer -> west double doors -> **Bird Hall** (stumble, break a vase, find the switch, the lantern). With Mary Sue in hand: out by the east door -> the grand stair "by the door" -> upper balcony -> **left, right, left some more** (U1 -> west back corridor -> U5) -> closet.
* **Act 5/6:** off-plan dream space (maroon hall, Wisconsin kitchen, forest corridor, lake). Not on the plan.
* **Act 7:** wake in U3 -> Portrait Hall (U2) -> across the bridge -> down the grand stair "ducking large chandeliers every few steps" -> round the corner -> Dining Room (G5).
* **Act 8:** Dining -> Kitchen -> the back-stair door **(impossible: the kitchen's far door opens onto the upper floor)** -> Military Gallery -> Bird Statue Room -> Gold Statue Room -> "bolted back downstairs" by the main stair -> Kitchen.
* **Act 9:** Kitchen/outside -> lawn -> woods -> shed (axe) -> house (bar cart) -> grand stair -> East Wing upper (pot) -> tumble down the stairs with it -> out and down the slope to the woodpile -> back and forth -> the fire -> bed (U3).

## Exterior: the clearing (Acts 3 and 9)
An oval grassy clearing about 140 m x 100 m ringed by thick forest (live oak, cedar, tall pine). Dry hot-country grass (no snow). A **winding dirt path** enters from the south forest edge at (0,+130) and snakes to the front steps at (0,+22). The **shed** stands near the west tree line around (-45,+35); the **woodpile / stump / chopping place** is near the shed. A **slope** falls away to the south-east at about (45,+45), where the pot is rolled and the **fire** is lit around (50,+55). The glass dome is the one thing visible from the forest road. Grackles (birds) in the oaks.

## Other places
* **The Wisconsin house (Act 1).** A 1990s two-storey suburban house, front door onto a snowy yard and driveway (the 1994 Ford Taurus). Rooms used: **living room** (the Carrington family's *27-inch RCA CRT television*, a couch full of hypnotised family, paneling, carpet, a framed print or two), **kitchen** (stained cupboards, tacky marble flooring, the yam, the grime-fighter solution, a wall phone), **hall closet** (the broom), **Mary Sue's room** (the fish tank). Everything specific, mid-priced and a little tired. This kitchen is reproduced exactly in Act 5.
* **The road (Act 2).** A two-lane road at night through woods at the shoulder; segments generated from a handful of hand-built set-pieces: the warning verse's "come this far no further" sign-less fork, an inn's lights going past (**do not stay**), the long straight, hills to launch over, the racoon at a trash can. See `docs/ACTS.md` Act 2.
* **The maroon hall (Act 5).** Not on the plan: an endless-feeling corridor of identical doors lit by chandeliers in ruby light; it leads to the Wisconsin kitchen (a door "wholly identical to many she had passed"), later narrows, the walls become round and textured, the chandeliers milkier, and it opens onto a forest path.
* **The lake (Act 6).** A dusk forest path, a clearing where the sky opens over a glassy lake that never meets it; a canoe tucked under a tree with Clement in it, a rod cast, the bobber, reeds, grackles.
* **The moon.** Seen through the dome (Act 3), a window (Acts 7-9), and in the sky.

## Wrongness registry per space (examples; each is an entry the WrongnessDirector can drive)
* Foyer: the chandelier's crystals slowly outnumber what they should; the umbrella urn holds one more umbrella each time.
* Stair Hall: the stairs have one step too many going up than coming down; a chandelier hangs where there was none.
* Bird Hall: the number of birds on the lantern is never twelve when you count; the dirt floor is damp.
* Portrait Hall: the paintings' eyes follow; the Beatles' crowd is larger each pass.
* Master bedroom: the pillows are never seven; the bed is slightly too wide.
* Dining: the table gains seats; Frank is not where he sat.
* Enfilade: the statues face the doorway you are in; the sightline is longer than the rooms allow.
* East wing: the decay is fresher than it should be.

## Dressing checklists (the "set dresser" pass)
Each room task lists 40-80 specific objects before building, using references of real rooms of that kind. Examples: **Wisconsin living room:** recliner, VHS cabinet and tapes, afghan, TV Guide, remote with tape, dust on the TV top, family photos, thermostat, floor vent, carpet vacuum lines, a bowl of hard candy. **Mansion kitchen:** copper pots, spice rack, butcher block, ice box door, dumbwaiter hatch, servant bell board, flour bin. **Dining room:** runner, candelabra, place settings for twenty, a tureen, napkin rings, a silver serving cart. Real, specific, slightly wrong.
