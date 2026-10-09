# TASKS (shared queue - edited ONLY by scripts/tools, never by agents)
Line format: `- (ID) description | needs: IDs or - | ch: chapters or - | STATUS`   STATUS = TODO / IN-PROGRESS / DONE
`make_context.sh` claims the next TODO task whose `needs` are all DONE. A task can be bigger than one chat: it is finished in many small steps.

## Foundation (build first; everything else uses these)
- (F-01) Dialogue runner: JSON dialogue, typewriter 38cps, choices 1-4, canon funnel, last-12-lines log, speaker blips hook | needs: - | ch: - | DONE
- (F-02) Interaction system: camera raycast, [E] prompt, reticle, outline highlight, interactable base script | needs: - | ch: - | DONE
- (F-03) HUD: flea jar, 4 hearts, objective line, caption box + speaker tag, floating meter ticks | needs: F-01 | ch: - | IN-PROGRESS
- (F-04) Post-process shader (vignette, grain, chroma, grade, bloom approx, flea overlay) + per-chapter grade table | needs: - | ch: - | TODO
- (F-05) Cutscene helper: camera presets, letterbox, fades, hold-Space skip, chapter title cards | needs: - | ch: - | TODO
- (F-06) Pause menu, settings (quality, volume, sensitivity, reduced motion, assist) and Treasure Notepad UI | needs: F-03 | ch: - | TODO
- (F-07) Moon + eye reusable scene: crater sphere, socket, lids, cornea, iris; API open/close/blink/look_at/pupil | needs: - | ch: - | TODO
- (F-08) Audio autoload: buses, per-character voice blips, SFX recipes, ducking, reverb | needs: - | ch: - | TODO
- (F-09) Music sequencer: music box + pump organ waltz, per-chapter variations | needs: F-08 | ch: - | TODO
- (F-10) Prop kit: chandelier (8+ arms, crystals; brass/ruby/milky), armor (12+ pieces), bird nest, RCA TV, picture frames | needs: - | ch: - | TODO
- (F-11) Birds: hero bird + MultiMesh flock (60-120), 12 species palettes, simple boids | needs: - | ch: - | TODO
- (F-12) Character kit: Christopher hands, Elsa Ray, Mary Sue, Frank, Sweaty Man, gold statues, expression swap | needs: - | ch: - | TODO
- (F-13) Title screen with moon hero shot, rhyme line, Begin/Chapters/Settings | needs: F-07,F-05 | ch: - | TODO

## Chapters (replace the stub scene; keep the chapter_id/ChapterBase contract)
- (C-01) Ch1 The Fourteenth of September: living room, Sweaty Man, letter UI, boot-kick, broom vs TV | needs: F-01,F-02 | ch: 1 | TODO
- (C-02) Ch2 Burning Bridges, Drowning Phones: throwing mini-game, Taurus load | needs: F-02 | ch: 2 | TODO
- (C-03) Ch3 The Road South: night driving game, racoons, inn, Elsa's voice, dawn arrival | needs: F-03 | ch: 3 | TODO
- (C-04) Ch4 The House in the Clearing: aerial approach, locked-door hallways, stairs | needs: F-02 | ch: 4 | TODO
- (C-05) Ch5 The Moon With an Eye: dome dialogue + stare-down | needs: F-01,F-07 | ch: 5 | TODO
- (C-06) Ch6 The First Night of Rooms: dark rooms, 12-arm bird lantern, chase, closet, cyclone | needs: F-02,F-10,F-11 | ch: 6 | TODO
- (C-07) Ch7 Thirteen Candles: maroon hall, kitchen, cake game, song game, transformation, forest corridor | needs: F-01,F-12 | ch: 7 | TODO
- (C-08) Ch8 The Lake: Clement, memory flash, fishing game, "Hello, son." | needs: F-01,F-12 | ch: 8 | TODO
- (C-09) Ch9 Morning at the Gronfiser's: pillows, painting hall, dining talk, Gronfiser verse, hard question | needs: F-01,F-02,F-10 | ch: 9 | TODO
- (C-10) Ch10 The Inventory: Notepad exploration, armor/bird/statue rooms, Flea takeover | needs: F-02,F-10,F-12 | ch: 10 | TODO
- (C-11) Ch11 The Melting Spree: bags, confrontation, axe, pot, fire, flute dance, collapse | needs: F-02,F-10 | ch: 11 | TODO

## Final
- (Z-01) Integration pass: play start to finish, fix chapter transitions, meters carry over, no console errors | needs: C-11 | ch: - | TODO
- (Z-02) Polish: lighting, particles, sound, text timing, performance/adaptive quality | needs: Z-01 | ch: - | TODO

## Needs the human (not claimable)
- Source story text for verbatim passages (letter, moon dialogue, father-argument, Gronfiser verse, Elsa lines). Until then: `TODO_VERBATIM`.
- Audio approach decision (default: procedural SFX/blips; free CC0 samples OK for ambience).

## Proposed by agents (claimable like any task)
- (P-F-02-1) Test runner script: run every tests/*.tscn headless and report PASS/FAIL | needs: - | ch: - | TODO
- (P-F-01-1) Add `dialogue_id` export to Interactable so props can start a dialogue with no script | needs: F-02 | ch: - | TODO
