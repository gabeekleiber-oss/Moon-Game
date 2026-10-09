# DESIGN

> Changing this file requires the Lead. Others propose changes in HANDOFF.md.

## One-sentence goal
A man who thinks he is the emperor of his household drives his family south to claim a fortune,
and the house, the moon and his own memories keep trying to teach him what he refuses to see.

## Priorities (in order)
1. Fidelity to the story (see CANON.md)
2. Visual richness: every chapter a distinct hand-built diorama (own light + palette)
3. Playability: every chapter has a real mechanic, not just a cutscene. Target 25-40 minutes.
4. Embellishment that serves the tone (props, jokes, sound, mini-mechanics) without contradicting canon.

## Tone
Wes Anderson dollhouse x fever dream x Dr. Seuss limerick. Broad sincere comedy over real sadness.
Play laughs straight, let the grief sneak up. Arc: bluster -> edge of understanding -> slide back
into obsession (the melting spree). No jump scares, no gore, no generic horror.

## Motifs (recur constantly)
- **The Moon**: milky, huge, eventually with a green-and-blue eye. Watches every chapter. Title = the family hangs from it.
- **Fleas of the mind**: intrusive impulses; glowing sparks crawling along screen edges.
- **Rhyme**: narration, signs, lines. The more manic Christopher, the more everything rhymes.
- **Gold, birds, racoons, kites, fish**: each owns a chapter.
- **Chandeliers**: everywhere; colour tells you which reality you're in.

## Governing principle
Every place is a piece of Christopher's interior (living room = control; road = numbness; mansion =
inherited worth; dome = being seen; bird hall = nurturing he treats as threat; kitchen = missed time;
lake = inherited silence; day mansion = value over people; fire = compulsion).
**Baseline then violation:** spend 20-40 s making each location believable, then break exactly one rule.

## Core systems
- **Flea Meter (0-100):** rises on impulse (smashing, throwing, drinking, ignoring family), drops on tenderness
  (listening, hugging, patient fishing, singing). Effects scale: screen-edge flea sparks, vignette pulse,
  buzzing whisper, text rhymes more; at 70+ gold dollar-sign motes + FOV breathing.
- **Household Heart (4 hearts):** Elsa Ray, Mary Sue, Frank, Self (0-10, start 6). Changes dialogue
  flavour and epilogue lines; NEVER changes main plot beats. Canonical ending is fixed.
- **Treasure Notepad (Q):** persistent handwritten list of owned items; main collectible system from Ch10.
- **Interaction:** raycast from camera, outline highlight, [E] prompt, funny response on most things.
- **Choices:** binary/ternary; the canon option is always available and unmarked; alternatives = comedy or
  extra Flea, then funnel back to canon within 1-2 nodes.
- **Appraisal Gaze (Ch9+):** objects sprout gold price tags; family desaturates/softens as Flea rises; by Ch11
  family are flat silhouettes unless player holds F to "see them" (restores colour, lowers Flea, tender
  micro-moment). Optional; colours epilogue only.

## Controls
WASD move, mouse look, E interact, Space jump/context, Shift sprint, C crouch, Q notepad, F see family, Esc pause, ` debug.

## Palettes (per chapter)
Ch1 cold blue night + warm lamp amber | Ch3 inky black, white headlights, racoon eyeshine | Ch4 dawn peach/rose/dusty gold |
Ch5 silver-milk + ink blue | Ch6 dark -> green-gold, dirt-brown, warm nests | Ch7 hall ruby-maroon; kitchen 90s yellow-beige + tacky marble |
Ch8 violet dusk + glassy teal | Ch9 honey sunlight, cream | Ch10 gold, black, red | Ch11 orange, whiskey amber, black trees.
Keep local material colours (brick stays brick); grade via light + fog tint, never a flat filter.

## Milestones
- M0: Skeleton, 11 chapter stubs, debug select  <- current
- M1: Core systems (HUD, dialogue, interact, post-fx, moon+eye) + Ch1-3 vertical slice
- M2: Ch4-7
- M3: Ch8-11
- M4: Polish, audio, performance, export
