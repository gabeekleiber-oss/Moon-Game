# TASKS
Format: `- [ ] (ID) Description - role - status`. Claim: `IN PROGRESS (date)`.

## Decisions needed from the human (blockers)
- [ ] (T-001) **Audio approach**: fully procedural synth (as brief) vs free CC0 samples? (default: procedural SFX/blips, CC0 allowed for ambience)
- [ ] (T-002) **Source story text**: provide the actual story so verbatim passages (letter, moon dialogue, father-argument, Gronfiser verse, Elsa lines) can be used accurately.
- [ ] (T-003) Create GitHub repo, push this skeleton, share clone URL with all 5 accounts.

## Lead / Core
- [ ] (L-01) HUD: Flea jar, 4 hearts, objective line, caption box, speaker tag, floating meter ticks
- [ ] (L-02) Dialogue runner (JSON, typewriter, choices 1-4, canon funnel, log of last 12 lines)
- [ ] (L-03) Interaction system (raycast, prompt, reticle, outline highlight) + interactable base
- [ ] (L-04) Post-process shader (vignette/grain/chroma/grade/bloom approx) driven by Flea + per-chapter grade table
- [ ] (L-05) Cutscene helper (camera presets, letterbox, fade, skip-hold) and chapter title cards
- [ ] (L-06) Pause menu, settings (quality, volume, sensitivity, reduced motion, assist), Treasure Notepad UI
- [ ] (L-07) Title screen with moon hero shot

## Assets / Audio
- [ ] (A-01) Moon + eye (hero asset): crater sphere, socket, lids, cornea, iris, blink/track/dilate API
- [ ] (A-02) Audio autoload: buses, voice blips per character, SFX recipes, ducking
- [ ] (A-03) Music sequencer: music-box/organ waltz, per-chapter variations
- [ ] (A-04) Prop kit: chandelier (>=8 arms, crystals; brass/ruby/milky), armor (>=12 pieces), nest, TV, painting frames
- [ ] (A-05) Birds: hero bird + MultiMesh flock (~60-120), 12 species palettes
- [ ] (A-06) Character rigs: Christopher hands, Elsa, Mary Sue, Frank, Sweaty Man, statues
- [ ] (A-07) Ch10 The Inventory
- [ ] (A-08) Ch11 The Melting Spree

## Slice (Ch1-3)
- [ ] (S-01) Ch1 living room diorama + TV + letter UI + kick + broom/TV smash
- [ ] (S-02) Ch2 throwing mini-game + Taurus load
- [ ] (S-03) Ch3 driving game (chase cam, hazards, inn, Elsa voice, dawn arrival)

## Mansion (Ch4-7)
- [ ] (M-01) Ch4 exterior approach + locked-door hallways + stairs
- [ ] (M-02) Ch5 dome dialogue + stare-down
- [ ] (M-03) Ch6 dark rooms, bird lantern hall, chase, closet, cyclone
- [ ] (M-04) Ch7 maroon hall, kitchen, cake game, song rhythm game, transformation, forest corridor

## Dream/Day (Ch8-9)
- [ ] (D-01) Ch8 lake, father scenes, memory flash, fishing game, "Hello, son"
- [ ] (D-02) Ch9 pillows, painting hall, dining conversation, Gronfiser verse, hard question
- [ ] (D-03) Epilogue / credits flourish

## Done
- [x] (T-000) Skeleton, docs, Game state/Flea/Hearts/Notepad, ChapterManager, 11 chapter stubs, DebugMenu
