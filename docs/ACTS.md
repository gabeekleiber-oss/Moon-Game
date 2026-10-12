# ACTS: the story, in order

The game is **nine acts**, strictly in order. Inside an act the player is free; the act's **beats** (ids below, used as `actN.beat` in room data and code) are done by doing the things the book says. When the last beat is done, the world gives the **unlock cue** and the next act opens (`Acts.unlock`, `ActBase.finish`). The verbatim story text for each act is added to your bundle by `scripts/tools/story_act.sh N`; copy lines exactly, including original typos. Never invent "verbatim" lines.

`Floor` is the act's minimum Unreality (`unreality_floor`); `Grade` is the location mood (`UnrealGrade.names()`).

## The nine acts
| # | Title | Place | State | Floor | Grade |
|---|---|---|---|---|---|
| 1 | The Fourteenth of September | Wisconsin house | winter night, TV light | 0.00 | flat_tired |
| 2 | The Road South | the night road, the Taurus | night, headlights only | 0.12 | road_black |
| 3 | The Moon With an Eye | clearing, mansion, dome | hot dawn, then dark | 0.22 | dawn_dome |
| 4 | The First Night of Rooms | Bird Hall, west wing, closet | pitch dark | 0.32 | pitch_dark |
| 5 | Thirteen Candles | maroon hall, Wisconsin kitchen | dream | 0.42 | maroon_dream |
| 6 | The Lake | forest path, lake | dream dusk | 0.50 | lake_dusk |
| 7 | Morning at the Gronfiser's | mansion upper floor, stairs, dining room | DAY | 0.50 | false_morning |
| 8 | The Inventory | kitchen, enfilade (armour, birds, gold) | DAY | 0.58 | gold_stillness |
| 9 | The Melting Spree | house, east wing, clearing, the fire | afternoon to FIRE night | 0.72 | fire_night |

Unreality rises *within* each act by drift, beats and shocks, so by the end of an act the level is above its floor and below the next floor. Never let it drop.

---

### Act 1: The Fourteenth of September
**Place:** the Wisconsin house (living room, kitchen, hall closet, Mary Sue's room, front door, yard). **Feel:** an ordinary evening; the family hypnotised by the television; comedy at the front, a chill under it.
**Player verbs:** look around, kick (with a boot), take a thing, shoo, swing a broom handle, make a call and *put the phone down*, throw (phone, then fish tank), carry, get in a car.
**Beats (in order):**
1. `intruder` - the family watches the annual rerun; a barefoot man in a bathrobe, dripping in sweat, bursts in.
2. `finger` - he presses a long finger to your lips and says "Relax, I come bearing gifts." **SHOCK 1** (touch, breath, damp robe; first-person; no jump scare).
3. `letter` - the slightly damp letter "baking like the sun"; read it (the verse letter; Joshua Primo, the Gronfiser; "thirteen years").
4. `shoo` - shoo the old hoot out with a kick of the boot; he runs off into the sun (it is night: the sun is the first wrong thing).
5. `kitchen_items` - in the kitchen take the yam and the grime fighter solution and set them on the floor.
6. `broom` - take the broom from the closet.
7. `tv_hit_1` - thrust the handle into the mouth of the actor on the TV; the song stops flat; the screen goes black.
8. `tv_hit_2` - do it once again; the Carrington family 27" RCA CRT falls to the floor. (Hit it **twice**.)
9. `quit_call` - phone the boss, quit.
10. `phone_throw` - throw the phone into Mary Sue's fish tank.
11. `tank_throw` - throw the tank as well.
12. `family_loaded` - Mary Sue, Frank and Elsa Ray crammed in the back of the 1994 Ford Taurus; the **letter rides in the passenger seat**.
**Wrongness:** the sun outside at night; the Sweaty Man's finger is longer than it should be; the TV's song continues faintly after the TV is dead; Elsa's eyes on you for half a second too long (her "glare").
**Unlock cue:** the Taurus's headlights come on by themselves and the engine turns over; the passenger-side dome light lights the letter.
**Sound:** TV audio (a pastiche, never a real song), snow-muffled outside, the Sweaty Man's wet footsteps.
**Note:** the TV scene names a real actor in the story's own words ("Christoper Plummer"); keep the line verbatim, never model or imitate a real likeness.

### Act 2: The Road South
**Place:** a long night road, the Taurus interior, a corridor of woods. **Feel:** hypnotic, lonely, getting stranger; the road becomes a *game* in his head.
**Player verbs:** drive (WASD steering, gas, brake), look, stay on the road. The "game" parts (up the hill, down the hill, gun it and brake, stay in the air and fall down and shake) are **driving feel**, never a score.
**Beats:**
1. `leave_house` - pull out of the driveway; the house falls behind.
2. `night_road` - the night is "swift and black like a racoon chasing the rubbage into the woods".
3. `woods_warning` - the warning verse: come this far no further; stay to the left; do not stay in the inn; stay away from the trees. (Presented as narration/verse, not a sign.)
4. `inn_passed` - pass the inn's lights without stopping.
5. `stay_left` - keep to the left of the road (the verse's instruction).
6. `racoon` - the racoon in the headlights at a trashcan, a thousand o' miles away.
7. `road_game` - the "rhyme of the road": hills, gunning and braking, the weightless drop; the feeling that makes the mind forget.
8. `elsa_voice` - Elsa Ray's voice buzzes like a bee, a flea; you hear but do not listen, her message is clear.
9. `dawn` - hot light; no more snow.
**Shocks:** a face at the inn's window that is yours (brief, optional; no jump).
**Wrongness:** the trees step closer when you are not looking; the headlights show a road that is slightly wider; the dash clock disagrees with the radio; Elsa's voice does not come from Elsa.
**Unlock cue:** dawn light hits a **dirt path** ahead; cicadas; the heat shimmer.

### Act 3: The Moon With an Eye
**Place:** the clearing, the mansion exterior, Foyer, Stair Hall, north balcony, Dome. **Feel:** arrival, awe, then the first real fear.
**Player verbs:** drive up the winding path, bound up the steps, try doors, climb stairs, look up, **answer back**.
**Beats:**
1. `arrive_5am` - the house in a grassy clearing surrounded by thick forest; oak and red brick, windows, chimneys galore.
2. `path_up` - drive up the winding dirt path.
3. `steps` - bound up the steps and cross the threshold into the dark house.
4. `locked_doors` - try a door: locked; another opens; a hallway of more locked doors and one open one.
5. `staircase` - the staircase up.
6. `dome` - the room with the giant glass dome and the moon, milky and bright.
7. `moon_eye` - **SHOCK 2**: the moon grows an eye, green and blue, and speaks: "Christopher, old friend, welcome home." (The only saturated colour in the game.)
8. `friend_dialogue` - the argument: "no friend of I"; "the Errante, your once closest friend"; "I am the Gronfiser, your uncle is dead, I am your uncle, your father, and friend." (verbatim)
9. `deny_threat` - "You lie again!... Mention the Gronfiser, or my father, once more, and youll pay!"
10. `eye_vanishes` - the eye vanishes; "Depart from me now".
**Wrongness:** the house is bigger than the plan allows; the dome's glass has no reflection of you; the moon's light falls on you from the wrong side.
**Ambiguity (CANON):** never confirm or deny what the Errante is.
**Unlock cue:** the dome goes dark and the **house lights die**, one chandelier at a time, from the top down; far below, a bird calls.

### Act 4: The First Night of Rooms
**Place:** the dark mansion: Bird Hall, west back stair, closet suite. **Feel:** blind, comic, panicked. The darkest act.
**Player verbs:** stumble, collide, find a switch, pick up (Mary Sue), run, throw, hide, be swept up. **No flashlight**: you blunder; sound and bumping guide you.
**Beats:**
1. `stumble` - pitch black; knock fixtures; a vase shatters.
2. `switch` - find the switch ("the most marvelous thing").
3. `lantern` - the lantern lights above: **twelve arms, each a different bird nest, different birds in each**.
4. `birds` - birds gather sticks and worms from piles; the floor is dirt with rugs.
5. `pick_up_mary_sue` - lift Mary Sue from the rug.
6. `leave_the_girl` - the lantern flickers; the birds: "leave the girl".
7. `defy` - shake your fist: "make me".
8. `run_stairs` - run through the house, up the stairs by the door, left, right, left some more.
9. `closet` - Mary Sue squirms in your fist, knuckles white; throw her into the closet; run through clothes, cloth, moth, silk, linen, a bundling swath.
10. `birds_sing` - cast off the clothes; the birds find you and chant ("the girl, the girl, she must be found... reel in the reel").
11. `cyclone` - a great glutenous gust sucks in the birds, your daughter, the kite and you; tumble in a cyclone of objects and feathers.
**Shocks:** the birds speak; the throw (a *child* in your fist; make the player feel the grip).
**Wrongness:** the bird count is never twelve; the left-right-left route is longer each time; the closet's clothes do not end; Mary Sue is lighter than she should be.
**Unlock cue:** the wind stops; Mary Sue is holding the **kite** with the birds circling it; she says "Follow me father." (the ruby light of the next hall bleeds in.)

### Act 5: Thirteen Candles
**Place:** the maroon hall of identical doors; the Wisconsin kitchen (exact replica). **Feel:** warm, domestic, then slowly horrifying: the faces change.
**Player verbs:** follow, walk, sit (take the head seat), eat, sing (hold to sing along in time with the birds' choir; no score), watch.
**Beats:**
1. `follow` - follow Mary Sue down a dark hallway turned ruby maroon by sparse chandeliers.
2. `identical_door` - she stops at a door wholly identical to many she has passed and beckons you in.
3. `kitchen` - the Wisconsin kitchen "I knew all too well": stained cupboards, tacky marble. Frank, Elsa Ray and Mary Sue (at the head).
4. `seat` - take the seat left for you.
5. `hat` - Elsa Ray gives Mary Sue a gold-speckled cone hat; the pink and white cake; **thirteen candles**.
6. `cake` - Elsa Ray cuts it: one for Frank, one for her, one for each of the birds on the floating kite; a slice for you.
7. `sing` - "Thank you mother... Now you must sing!" A triumphant choir of birds.
8. `faces` - **SHOCK 3:** Mary Sue's face is no longer a child's (golden hair, the dance of her eyes, her mother's face); Elsa Ray's hair dulls and her face is "thinner and longer, pulled towards the earth". The narration slips from "I" to "he" and "Christopher". The woman he met is gone.
9. `frank_exchange` - "You see him now, don't you." / "Yes I do." / "Then you are ready to see him once more." / "Your grandfather is dead." / "You saw him in me. It is time to see him again." (Frank is Clement for a beat; never explained.)
10. `frank_leaves` - Frank hugs his sister and walks into the hallway; follow.
**Wrongness:** the candles are lit before anyone lights them; the birds' beaks are "a sprinkled, disgusting mess"; the number of chairs is wrong; the singing continues after the mouths close.
**Unlock cue:** the walls become round and textured, the ground coarser, the chandeliers milkier; the hall gives way to **a forest path** (smell of earth).

### Act 6: The Lake
**Place:** forest path, clearing, a glassy lake, a canoe under a tree. **Feel:** the one soft, sad act: quiet, huge, dreamlike.
**Player verbs:** walk, talk (choose to speak or stay silent; no scoring), sit in the canoe, cast/reel (a *gentle, forgiving* fishing action with no meter), watch the bobber.
**Beats:**
1. `walk_forest` - a deep forest path, barely past dusk, stars in clusters like the fixtures of the Gronfiser's home.
2. `clearing` - the sky opens over the lake; "never the two would meet".
3. `father_in_canoe` - Clement, seated in a canoe under a tree, rod cast, the bobber still.
4. `frank_argument` - Frank at the wood's edge: "There is your father. Go speak to him now / For as long as the errante will choose to allow." The verse argument (verbatim).
5. `approach_canoe` - sit in the canoe.
6. `speak_to_father` - the long speech to a father who says nothing.
7. `memory` - Edith's truck, the sobbing, the road, the moon on his skin (a brief memory visual; Edith is a **silhouette only**).
8. `plead` - "Father, I beg you, speak to me now!"; the bobber begins to drift.
9. `curse` - "God Damn you, father"; turn to the woods to find Frank; the woods are empty.
10. `grackle_bass` - a grackle shoots over the lake; the rod bucks; Clement jolts it and reels in a great bass that flops into the boat.
11. `remembering` - Friday nights, the truck, lures; the dying wish: take your own children fishing.
12. `deep_breath` - take a breath; look at the trees, the lake, the reeds; be drawn to the light of the moon.
13. `hello_son` - **SHOCK 4:** "Hello, son." (Clement's first and only line; never explained.)
**Wrongness:** the lake is perfectly still except the bobber; the moon is both above and in the water at once; Clement's face is where it is not; ripples go inward.
**Unlock cue:** cut to black; the sound of toast and eggs and chatter through floorboards.

### Act 7: Morning at the Gronfiser's
**Place:** the master bedroom (U3), Portrait Hall (U2), the grand stair, the Dining Room (G5). **State:** DAY. **Feel:** bright, cheerful, warm, quietly *false*.
**Player verbs:** wake, make the bed (seven pillows in a row), walk, duck, sit, listen, answer.
**Beats:**
1. `wake` - the room is empty; noises of chatter downstairs; the smell of eggs and buttered toast.
2. `bed` - make the bed: all seven pillows with the Gronfiser's seal, in a row.
3. `portraits` - the hall paintings in the midday sun: the pope licking a golden boot; the Gronfiser performing with the Beatles, signature trombone, crowd of 300,000. (Stylised, no real likenesses.)
4. `stairs` - down the stairs, ducking large chandeliers every few steps.
5. `dining` - the dining room; the family eating at the far end of the twenty-seat table; take the head seat, **eighteen seats from Frank**.
6. `breakfast_talk` - "So, gang. How was your first night...?" Frank on beds; Mary Sue on the phone in the fish tank; Elsa on the quiet.
7. `gronfiser_verse` - "It was the Gronfisers, of course!" the long rhyming verse about Joshua Primo (verbatim).
8. `heir_answer` - why he left it to us: "The Gronfiser had no children of his own..." (verbatim).
9. `hard_question` - "What happened?" / "Why didn't you become the gronfiser?" / "**I left. When they both died.**" (**SHOCK 5:** the room's warmth drains; his voice lurches octaves.)
10. `elsa_glare` - Elsa's glare; the children clear the plates and leave you alone.
**Wrongness:** the day is *too* bright; the chatter downstairs was too many voices; the paintings' crowds grow; your family's faces are each a half-second late.
**Unlock cue:** alone at the table; a **notepad and a pen** are on the table where nothing was.

### Act 8: The Inventory
**Place:** the Kitchen and the enfilade: Military Gallery, Bird Statue Room, Gold Statue Room. **State:** DAY. **Feel:** acquisitive, spacious, increasingly possessed.
**Player verbs:** explore freely, look at things, write them down (tally the treasure in a **physical notepad**, no score screen, no running total shown to the player), walk the long vista.
**Beats:**
1. `notepad` - take the notepad and pen; "tally all of the treasures in the mansion" as he did in Wisconsin.
2. `military_gallery` - the first room out of the kitchen doorway: rows of armour and family crests; swords, a mace, a bayonet, a gun.
3. `bird_statues` - silver, gold and bronze bird statues on windowsills, next to the loveseat, on every fan blade, from the walls.
4. `gold_statues` - red carpet, black walls; Joshua Primo (elephant), Crumpis (baboon), Crumpalump (tiger), Curt (loon, 3 ft).
5. `funny_feeling` - "a funny feeling struck me in that room quite full of gold": stomach churning, heart bold. **The fleas begin.**
**Wrongness:** the statues *face* whichever door you stand in; the enfilade is longer than the building; the notepad's list is longer than what you wrote; the gold is warm.
**Unlock cue:** the fleas "hijack my own thought train": the room's gold *glints* and the first **dollar-sign shimmer** passes the periphery; his own voice repeats a plan; the world tilts toward the east wing and the back door.

### Act 9: The Melting Spree
**Place:** house (everywhere), the lawn, the shed and woods, the east wing, the clearing, the fire; the master bedroom. **Feel:** manic, escalating, exhilarating, awful. The peak.
**Player verbs:** run, grab (bags of treasure), yell, jig, chop (axe: a satisfying *physical* swing and split), carry the great pot, roll it, strike matches, throw things on the fire, play the flute and dance around the fire.
**Beats:**
1. `plan` - the melting plan: turn gold and silver into bars and be richer than the tsars.
2. `family_bags` - rush to the kitchen yelling "we're rich"; the jig of the oil rig; the family grabs garbage bags and poaches silverware, candlesticks, trinkets.
3. `lawn_dump` - hoist the sacks outside to melt the gold, bronze and brass.
4. `elsa_confrontation` - "Christopher, I worry about you..." (verbatim verse quarrel); a light kiss; sprint into the woods.
5. `axe` - find an axe behind the shed.
6. `chop` - chop and stack; split the logs down the middle; whisky sours.
7. `east_wing` - the fleas sing: go to the east wing; cobwebs, tapestry tears, decay.
8. `pot` - find the gigantic painted-elephant pot made for smelting.
9. `stairs_fall` - set it on your neck; tumble down the stairs; face on the deck; get up.
10. `roll_pot` - carry it outside; roll it down the slope to the woodpile.
11. `light_fire` - matches; the fire burns bright.
12. `pot_on` - throw the pot on the logs; whiskey shot; **five chandeliers, nine dining sets and a necklace** into the pot.
13. `oil_flute` - lather yourself in oil; find a grand flute imported from France.
14. `dance` - play the flute and dance around the fire; the flute sound begins to dement; sing.
15. `bed` - check the fire is in order; stagger in; climb the stairs; collapse in bed next to sleeping Elsa Ray.
**Shocks:** the flute dance (a long rising sequence; no strobing); the pot's weight on your neck; the fall.
**Wrongness (peak):** the house is not where you left it; the staircase is a different length each descent; the fire is brighter than its fuel; the forest watches; the moon is closer.
**End of part one:** the bedroom window; the moon in it; **the eye opens** (final image; the story continues).

---

## Act-wide rules
* **The player triggers the next act** (car, dome stair, bed...) via `make_exit`; the cue only makes the exit noticeable, never forces it.
* **Beat order is law;** triggers may be generous but out-of-order calls are ignored (`BeatTracker`).
* Every act begins with the previous act's cue still audible/visible for a few seconds, so there is no hard cut in feeling.
* Every act has exactly the **shocks** listed above (no extras without a NOTES FOR DIRECTION entry and the human's approval).
* Verbatim text goes in `data/dialogue/actNN_*.json` or `data/text/`; narration verse is typeset by the narration presenter (`S-04`).
