# I've Hung You From the Moon

A realistic, unnerving, explorable **first-person experience** in **Godot 4.3 (GDScript)**, adapted from a surreal, rhyming, darkly comic horror story. You act out the story across nine acts, in strict order, while a hidden **Unreality** value (never shown) makes the world look, sound and behave worse. World-building, map design and art are the work; there is no score, health or HUD.
Built by several Claude agents working as interchangeable workers on a shared task queue in this repo.

**Platform:** Windows 10 (64-bit) minimum, Windows 11 supported. PC only (mouse + keyboard; gamepad later). Min spec: quad-core CPU, 8 GB RAM, Vulkan-capable GPU (GTX 960 / RX 470 class), ~6 GB disk. Target: 60 fps on a GTX 1660 / RX 580 at 1080p.

**Read in this order:** `docs/VISION.md` -> `docs/ART_BIBLE.md` -> `docs/WORLD_BIBLE.md` -> `docs/ACTS.md` -> `docs/CANON.md` (non-negotiable) -> `docs/ARCHITECTURE.md` -> `docs/IDEAS.md` (a big, deliberately messy pile of ideas; mine it) -> `docs/MASTER.md` (how the project runs).
**The story:** `docs/source/STORY.md` (verbatim, never edited). `bash scripts/tools/story_act.sh N` prints one act.
**Agents:** in Claude Code read `CLAUDE.md` and run `bash scripts/tools/start.sh`. In plain chats your rules are in your context bundle (`docs/CHAT_RULES.md`). Humans: `docs/MASTER.md` section 3.
**Assets:** `docs/ASSETS.md` (agents request, the human downloads from `docs/ASSET_REQUESTS.md` into `assets/_inbox/`).
**Previous prototype** (gamified chapters with HUD and meters): git tag `v1-gamified`.

**Run:** open `project.godot` in Godot 4.3+, press F5. Backtick opens the debug menu (act select, Unreality slider). `godot -- --act=5 --unreality=0.6` jumps anywhere. Tests: `bash scripts/tools/run_tests.sh`.
