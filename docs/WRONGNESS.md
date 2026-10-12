# WRONGNESS: how the world goes wrong (the contract between data, Unreality and S-07)

**Data:** `data/wrongness/catalog.json` (validated by `tests/test_wrongness_catalog`). **Art spec:** `docs/ART_BIBLE.md` section 1-2. **Runtime:** `Unreality` autoload + the WrongnessDirector (task `S-07`).

## Two lists
* `behaviours` (30): the reusable library. Implement each ONCE as a small script/resource (`lean`, `swap`, `count_wrong`, `corridor_stretch`, `turn_to_face`, `afterimage`...). Each carries its `observed` rule (WHEN it may change) and a `reduced_motion` fallback.
* `instances` (91, every one of the 53 spaces has at least one): a concrete wrong. `id` IS the `wrong_id`. Fields: `space` (a `data/world` id), `behaviour`, `acts` `[first,last]`, `tier` 1-3, `text` (what the player perceives), optional `scripted`.

## How an agent uses it
1. **Dressing a room:** open `data/world/<space>.json`, find that space's instances, put the id on the prop (`props[].wrong_id`), build the object so the wrong state is *possible* (a second pose, an extra node, a longer-corridor variant).
2. **Gating:** `Unreality.wrongs(id, bias)` is the deterministic per-object threshold (0.1..0.9, stable order every run). Use `tier` to choose the bias: tier 1 starts early (bias ~ -0.2), tier 2 neutral, tier 3 late (bias ~ +0.15). Never gate on `band()` alone.
3. **Observed rule:** `unseen` = change only while outside the camera frustum or occluded; `while_walking` = while the player is moving through it; `always`/`always_subtle` = static state. Nothing moves in plain view. Never snap a thing the player is staring at.
4. **Reduced Motion:** multiply any moving effect by `Unreality.motion_scale()`; at 0 use the behaviour's fallback (swap while unseen, hold a static variant).
5. **Add instances freely** (this is a living file): new id, existing space, existing behaviour. Run the test. Add a behaviour only when no existing one fits; implement it in the library, not in the room.

## Rules (from CANON / VISION)
No lore: a wrong thing is *physically* wrong, never explained. The Errante, Clement, Frank, "when they both died", Edith's flight stay ambiguous: no instance may confirm what any of them is. No strobing (>3 flashes/s). The few explicit shocks are listed in `docs/ACTS.md`; wrongness is not a shock source. Scripted face changes (`scripted: true`, e.g. Mary Sue in Act 5) are story beats, driven by the beat, not by the threshold.

## Pacing guide
Acts 1-2: almost only tier 1 (the sun at night, the TV afterimage, the road a little wide). Acts 3-4: tier 2 and the first tier 3 (dome, dark house). Acts 5-6: dream spaces, mostly tier 3 but *quiet*. Acts 7-8: DAY: tier 1-2 in bright light is the scariest thing in the game; keep tier 3 for the statues and the dining table. Act 9: tier 3 everywhere, light and fire doing most of the work.
