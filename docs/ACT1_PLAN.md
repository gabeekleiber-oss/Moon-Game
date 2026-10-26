# ACT 1 FIRST: finish "The Fourteenth of September" completely, then build the rest

Human direction: Act 1 must be fully playable, start to finish, in a real window, before any other act, the mansion, the road, birds, characters beyond Act 1, or Act 9 work is claimed. Everything outside Act 1 waits behind gate **G-02** in TASKS.md (the human sets it DONE after playing Act 1). Work already IN-PROGRESS may finish, but do not start new non-Act-1 work.

## Scope: Act 1 only
Spaces (data/world): `wi_living_room`, `wi_kitchen`, `wi_hall_closet`, `wi_marysue_room`, `wi_yard` (snowy yard and driveway), plus a static 1994 Ford Taurus. Existing scene: `scenes/acts/act01_wisconsin/`.
Beats (data/story/beats.json, in order of the source; completion order is free unless the source demands it): intruder, finger, letter, shoo, kitchen_items, broom, tv_hit_1, tv_hit_2, quit_call, phone_throw, tank_throw, family_loaded. Exact text only from `bash scripts/tools/story_act.sh 1`.
Not in scope: driving, the road, the mansion, birds, full realistic characters (use the S-08a "unfinished face" set), WrongnessDirector, Moon/Eye upgrade.

## Task path (everything else is gated)
S-05 RoomBuilder -> L-01 the Wisconsin house; S-08a fallback characters; S-13a static Taurus; S-15 physical verbs; S-11a/S-11 save and title -> A-01 story scripting -> A-01b playable build -> human gate G-02.

## Definition of "fully playable" (all must be true, checked in a real window by the human where noted)
1. **Flow:** Title -> Begin -> Act 1 -> end-of-act card ("Act 2 comes next", no driving). Continue restores a mid-act save (act, beat flags, Unreality).
2. **Every beat reachable and recorded once**, in any sensible order; the next-act transition never fires by itself: the player triggers it by getting into the loaded Taurus after `family_loaded`.
3. **Physical verbs feel good:** shoo, broom, hitting the TV twice, phone and tank throws, kitchen items, carrying Mary Sue. Forgiving, tactile, with sound; no meters, HUD, markers or objective list.
4. **The place:** all five spaces and the yard walkable with collision that agrees with the plan; believable 1990s clutter (27-inch RCA CRT, couch, fish tank, closet); every room dressed past greybox; no empty rooms.
5. **Look and sound:** practical lighting per room (TV flicker, lamps, snow light), room tone and per-room reverb, narration and verse typeset correctly, subtitles on, Reduced Motion respected, no flashing.
6. **Unreality** at its Act 1 floor: hidden, deterministic, shown only through the world (finger shock and intruder as authored).
7. **Quality gates:** `run_tests.sh` green, headless smoke loads every Act 1 room, no console errors on a full playthrough, frame time within the ART_BIBLE budget on target hardware, Windows export smoke test passes (S-17 tooling).
8. **Human playtest:** the human plays the whole act, lists issues, agents fix them (A-01b), then the human clears G-02.

## Rules for agents on this focus
- Pick Act 1 work first. If start.sh prints NO_TASKS, tell the human which gate or Act 1 task is blocking.
- Prefer finishing and polishing Act 1 over adding systems "for later". If you need a later-act system, stub locally and note it under NEEDS FROM OTHER TASKS.
- Placeholder art must be marked `# PLACEHOLDER`; a visual placeholder is not a finished art pass.
