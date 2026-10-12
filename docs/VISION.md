# VISION: what this game is

**In one sentence:** a realistic, unnerving, explorable experience in which you *act out* "I've Hung You From the Moon" as Christopher, while the world slowly comes apart with his mind.

It is **an experience game**. Most of the work, code and labour goes into *place*: the detail of the spaces, the light, the sound, the way things go wrong. There is nothing to win.

## The pillars (in priority order; when they conflict, higher wins)
1. **World first.** Map design and world building are the top priority. Every place is intricate, specific and close to real life: real floor plans, real clutter, real wear, real light. The player should feel they could walk this house in daylight and get lost in it at night. Detail beats features.
2. **Sanity is the renderer.** A hidden value, **Unreality** (0..1), rises over play and at story beats. The player never sees it: no meter, no number. The *art itself* reflects it: colour drifts, the lens bends, light flickers, sound detunes, geometry misbehaves, faces slip, the narration lies. Early in the game the world looks ordinary and slightly off; late it looks wrong in every way. (`docs/ART_BIBLE.md` is the full spec.)
3. **Psychological horror, with earned shocks.** Dread, wrongness and the uncanny come first. A few well-placed shocks (the finger on your lips, the moon's eye opening, a child's face that is no longer a child's) land harder because everything else is quiet. No gore for its own sake, no cheap jump scares, no random scares. **Explicit moments are allowed in a few deliberate, listed cases** (see docs/ACTS.md shocks and docs/IDEAS.md), never as a default tone.
4. **The player does what the book does.** Verbs come straight from the text: kick the door, take the broom to the television, quit the job, throw the phone into the fish tank, drive through the night, climb to the dome, grab your daughter in the dark, take your seat at the birthday cake, sit in the canoe, make the bed, tally the treasure, chop wood, carry the great pot, light the fire, dance. These are *physical, forgiving actions in the world*, not scored mini-games.
5. **Story in strict order, space open.** Act N+1 only opens when act N is done. Inside an act the player roams freely and does things in any sensible order. When a part is complete the world gives a **subtle but noticeable cue** (a light comes on, a lock clicks, a bird calls, a door that was shut stands open). **The next sequence only starts when the player chooses to trigger it** (gets in the car, climbs into the dome, lies down in the bed): the cue points at an exit, it never drags them on.
6. **The narrator is unreliable and cheerful.** The text is a sincere, rhyming, darkly comic first-person voice describing disasters as triumphs. The comedy and the dread are the same thing: the world gets worse while he keeps smiling.
7. **Words on screen, voices as sound.** Narration and dialogue appear as on-screen text (verse typeset as verse), and each character has a distinct speaking sound (a voice-blip) while their line types out. There is no recorded voice acting.

## What the player experiences
Walking (first person, hands visible), looking, interacting with objects with one button, carrying things (a daughter, a pot, an axe), driving, and listening. Pause menu with settings. That's it. No inventory screen, no health, no score, no timers, no meters, no objective list, no minimap, no tutorials beyond in-world hints.

## What we do NOT build
Scoring of any kind. Health or lives. Visible meters (the old Flea Meter jar and Household Hearts were removed in the redesign). Timing mini-games with bars (kick meter, throw meter). Collectible UIs. Branching endings. Anything that makes the player think about *winning* instead of *being there*. (The prototype that had these is preserved at git tag `v1-gamified`.)

## Scope of this game
This is **game one**: the nine acts in `docs/ACTS.md`, from the Wisconsin living room to Christopher collapsing into bed beside Elsa Ray. The source story continues beyond this; design the world so it can grow (the moon's eye opening at the end is a natural last image).

## Tone and boundaries
* Dread under comedy. Sincere grief under absurdity (Clement, Edith, "when they both died" are never explained; see CANON).
* The story names real people (a famous actor on the TV, a basketball player, the pope, the Beatles). Keep the *story's words* exactly as written, but **never model a real person's likeness**: paintings and TV figures are stylised, anonymous or silhouetted.
* Horror is psychological. Sudden, loud, graphic or violent moments are rare, deliberate, listed in `docs/ACTS.md` (a few may be explicit; the human approves each), and never use strobing (>3 flashes/second). Everything that moves has a Reduced Motion fallback.

## How we judge quality
Ask of every room, prop and effect: *Could this be a real place? Would a stranger believe it? Does it get worse in the right way?* Prefer one convincing room over five thin ones. Verify with a real-window screenshot or play, not only headless tests (see ART_BIBLE "Verification").
