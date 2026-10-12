# ART BIBLE: ordinary dread

**The look:** realistic, restrained, unnerving. The world is *convincingly real*, and the wrongness comes from how it is lit, coloured, heard and slowly rearranged as Christopher's mind slips. Never cartoon, never "horror filter". The wrongness is earned in small, specific, repeatable steps.

The hidden value is **Unreality** (0..1). Read it through the `Unreality` autoload (`docs/ARCHITECTURE.md`). **Every system that makes the world look, sound or behave must scale with it.** The screen layer (grade, lens, fleas) is already built; everything else in the tables below is work for the tasks in `docs/TASKS.md`.

## 1. The unreality curve (six bands)
Bands (also in code: `UnrealityModel.BAND_NAMES`): **0 ordinary (0-.15), 1 off (.15-.35), 2 wrong (.35-.55), 3 fraying (.55-.75), 4 unmoored (.75-.90), 5 ruin (.90-1)**. Acts set a *floor* (the story only gets stranger); a slow drift and story beats raise it; shocks spike it briefly.

| Layer | 0 ordinary | 1 off | 2 wrong | 3 fraying | 4 unmoored | 5 ruin |
|---|---|---|---|---|---|---|
| **Screen** (built: `UnrealGrade`, `post_fx.gdshader`) | clean film grade | faint extra grain, vignette +, chroma × 1.2 | colours drain (sat .88), hue drifts, faint bilious cast, lens begins to bend | sat .75, double vision appears, liquid sway, fleas begin at screen edges | strong warp, ghosting, heavy chroma split | over-saturated, warped, specks everywhere, vignette closing |
| **Light** | motivated, steady | one lamp hums | lights flicker rarely; shadows slightly too long | colour temperature wanders; a light source is wrong (cold lamp, warm moon) | shadows lag/point the wrong way; light pools where there is no source | light behaves like a character: leans toward the player, pulses |
| **Sound** | clean room tone | a faint tone under the room | music detunes a few cents; whispers at the threshold of hearing | dropouts, the room tone breathes, voices double | sounds arrive before their causes, speech is smeared | the soundtrack is the fleas |
| **World** | everything where it should be | one object slightly moved or tilted | doors count wrong; pictures slightly turned; clocks disagree | corridors a little longer each pass; rooms change proportion; symmetric things repeat | doors lead somewhere else; layouts contradict the plan; windows show the wrong hour | the building rearranges itself behind you |
| **People** | faces correct | a smile held a half-second too long | an eyeline that follows you; hands too still | features drift (older, younger, a relative's); lips late | faces smeared, doubled, wrong species of calm | no longer reading as individuals |
| **Narration/text** | plain | rare typo-like slip | words swim in place; a line repeats once | verse takes over prose; a word is replaced | the "I" slips to "he" and back (as in the cake scene) | text and voice-blips desynchronise |
| **Player feel** | steady camera | none | slight head drift | head roll and FOV breathe (built in `player.gd`) | stumbling sway, footsteps echo wrongly | the floor feels like the sea |

Authoring rules for any effect: **(a)** scale by `Unreality.ramp(a, b)` not by `if band == n`; **(b)** moving effects multiply `Unreality.motion_scale()` (Reduced Motion = 0); **(c)** subtle first: the player should *feel* it before they can *name* it; **(d)** prefer *accumulating* changes keyed on `Unreality.wrongs(id)` so things go wrong one by one in the same order every playthrough; **(e)** never change something while the player is looking at it unless it is a listed shock.

## 2. The wrongness catalogue (pick from this; add to it)
Visual/world: portrait eyes follow the player; the same painting appears one room later; a door that opened left now opens right; one extra step in a staircase; a corridor that is longer returning than going; chandeliers swing with no draft, then *breathe*; a window shows noon at midnight; a shadow with no object; a mirror-image room that is not quite a mirror; clocks run at different speeds; wallpaper pattern slowly crawls (the fleas); the dining table gains seats; the number of birds on the lantern is not twelve; objects are one centimetre closer than last time you looked; light switches that do the wrong thing; water that sits at an angle; scale shifts (a room that is 5% too large).
People: Mary Sue's face matures between two glances; Elsa's face "pulled toward the earth"; Frank *is* Clement for one beat; a family member in a doorway who was not there; the narrator's own hands a different age.
Rule: each is built as a small reusable behaviour registered with the WrongnessDirector task (`S-07`) with an id, a threshold bias, and a "not while observed" check.

## 3. Space by space: the visual language
| Space | Palette | Key light | Signature |
|---|---|---|---|
| Wisconsin house (Act 1) | desaturated 1990s beige, wood panel, cool blue shadow | the TV's blue flicker, one warm table lamp, grey day through blinds | lived-in clutter; the TV is the hearth. Everything *slightly* too tidy where Christopher "commands" it |
| The road (Act 2) | inky black, white headlights, amber dash, racoon eyeshine | headlights only | the trees are a wall at the edge of the beams; the world is only what the lights touch |
| Gronfiser exterior (Acts 3, 9) | hot dawn peach, dry gold grass, black forest | low sun, long shadows | oak and red brick, many windows, chimneys galore; the clearing is an island in a tall forest |
| Mansion at night (Act 4) | near black, green-gold nests, dirt brown | the lantern's warm flicker, moonlight through high windows | dark you must feel your way through; the birds are the light |
| The dome (Act 3) | silver-milk, ink blue | the moon | the only room that is *clean*; the moon is a presence |
| Maroon hall (Act 5) | ruby maroon, milky chandeliers | chandeliers, thickening | identical doors; the walls become round and textured toward the forest |
| Wisconsin kitchen replica (Act 5) | 90s yellow-beige, stained cupboards, tacky marble | a ceiling fixture | exactly right, which is the wrong thing |
| The lake (Act 6) | violet dusk, glassy teal | star-light and a pooled moon | a lake and a sky that never meet; the one place realism softens into dream |
| The mansion by day (Act 7) | honey sunlight, cream, oak | big south windows | cheerful, clean, quietly false; paintings of the Gronfiser's exploits |
| The enfilade (Act 8) | gold, black, red, bronze | warm spots on statues | rows of armour and statues that *face* him; the fleas rise here |
| The east wing (Act 9) | grey dust, cobweb, faded tapestry | shafts through broken blinds | neglect; the one place that has not been cleaned for him |
| The fire clearing (Act 9) | orange, whiskey amber, black trees | the fire (the only light) | everything is the fire; the sky is gone |

## 4. Lighting rules
* **Motivated light.** Every light has a visible source (lamp, window, TV, candle, moon). Unmotivated light is a *wrongness*, so it must be rare and deliberate.
* **Real darkness.** Interiors at night must be genuinely dark. Do not "ambient-fill" the problem away.
* **Colour temperature carries mood** (warm practicals vs cold moon). Use `UnrealGrade` base grades only to tie the frame together.
* **Budget:** at most 2 shadow-casting dynamic lights per view; everything else baked or unshadowed. Baked/probe lighting for interiors, volumetric fog for shafts, SSAO and glow on.
* The moon is a light source: milky, cool, slightly too bright.

## 5. Materials and assets (see also ARCHITECTURE "Assets and materials")
* **Real PBR everywhere.** Albedo + normal + roughness (+ AO/height). No flat-colour surfaces except where deliberate. Wear, dirt, grime, damp, dust, edge wear and decals tell the history of each room.
* **Sources:** free, license-clean assets only (CC0 first: Poly Haven, ambientCG, Quaternius, Kenney; anything else must be recorded in `assets/LICENSES.md` with its license and URL). Never commit an asset without its license line. Hero pieces (the moon, the pot, the TV, the letter) may be hand-built or modelled.
* **Procedural fallback:** if an asset is missing, a code-built placeholder must exist so the scene still runs (this is how `PropUtil`-style helpers were used). Placeholders are marked `# PLACEHOLDER` and tracked as tasks.
* **Unreality in materials:** every surface material that matters should react to the global shader values `unreality` and `unreal_time` (`scenes/fx/example_unreal_surface.gdshader` is the pattern): rot toward a sickly tint, texture swim, damp sheen. Subtle.
* **Texel density** about 512 px/m on hero surfaces, 256 elsewhere; textures 1-2K; model LODs for anything repeated.

## 6. People
* **Realistic, unsettling, never cartoon.** Believable bodies and faces, authored from CC0 base meshes/morphs, hair cards, a convincing eye shader. Mostly medium shots; long face close-ups are rare and deliberate (Mary Sue's face in the birthday scene is *the* close-up).
* **Face morphs are the horror tool:** an `age` morph (Mary Sue 12 -> adult; Elsa's face "thinner and longer, pulled towards the earth"), a `relative` morph (Frank -> Clement), and `wrongness` (smear, asymmetry, a smile held too long) driven by Unreality.
* **Fallback if photoreal faces are not achievable:** stylised-real figures with *unfinished* faces (smooth, softly blurred, features only suggested). This is deliberately eerie and is acceptable; do not ship uncanny-bad realism.
* Christopher is first person: **hands and forearms** only, in the clothes he quit his job in, and they age/shake as Unreality rises.
* Speech: each character has a voice-blip profile (exists: `scenes/audio/voice_profiles.gd`); on-screen text types in with the blip.
* **The Moon and its Eye** (exists as `MoonEye`, code-built; to be upgraded): milky cratered sphere; the eye is the *only saturated colour* in the game: **green and blue**. Wet cornea, veined sclera, lids of moon-skin. It must feel like an animal looking at you.

## 7. Camera, UI and accessibility
* First person, FOV 75, no HUD. Interaction hint is minimal and in-world (a subtle highlight; the `[E]` hint fades in only when relevant). Narration and dialogue are on-screen text at the bottom, readable at all times.
* **Reduced Motion** (Settings) removes sway, wobble, specks, chroma, flicker. **Subtitles are the text** and are always on. No strobing, ever (max 3 flashes/second, no full-screen flashes).
* Provide a "comfort" path: head sway off, FOV slider, sensitivity slider.

## 8. Audio
Layers per space: **room tone** (always), **ambience** (wind, cicadas, grackles, house settling), **spot sounds** (doors, floorboards, birds), **music** (the Moon Waltz as music box and pump organ; exists: `MusicScore`/`MusicSequencer`/`Instruments`), **voices** (blips). Reverb per room (preset system exists in `Audio`). Unreality bends all of them as in the table above. Silence is a tool.

## 9. Shocks
A "shock" is a scripted, single, earned moment: `Unreality.spike(0.15-0.3)` plus a sound and a visual beat. Listed per act in `docs/ACTS.md`. At most one per few minutes, never repeated, never in the first minute of an act, never with strobing, always with Reduced Motion alternatives (no flash, no shake).

## 10. Performance and verification
* Target 60 fps on a mid-range PC (GTX 1660 / RX 580 class) at 1080p. Budgets: ~2,500 draw calls worst case, instance anything repeated, bake lighting, LOD and occlusion for big interiors, stream the exterior.
* **Verification limit:** the agents' sandbox renders in *software* with the compatibility renderer (no SDFGI, no volumetric fog, slow). Headless tests prove logic only. **Any visual claim must be marked "unverified in a real window" in the HANDOFF NOTE**, and the human plays regularly. Do not claim something "looks good" from a software screenshot; claim it "renders and reads correctly".
