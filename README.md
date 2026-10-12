# I've Hung You From the Moon

A first-person psychological-horror **experience game** built in Godot 4.3+ / GDScript. The player physically acts out the original surreal, darkly comic story across nine linear acts, while being free to explore each space at their own pace. The environment gradually unravels around them through a hidden Unreality system—never a visible meter.

**This is not a scoring game.** No score, health, timers, objective list, minimap, or player-facing sanity number. The production priority is detailed, believable spaces; high-quality lighting and materials; sound; environmental interaction; and deliberate surreal escalation.

**Platform:** Windows 10 (64-bit) minimum; Windows 11 supported. Mouse + keyboard. Minimum planning target: quad-core CPU, 8 GB RAM, Vulkan-capable GPU around GTX 960 / RX 470 class, and approximately 6 GB disk. Target 1080p / 60 fps on GTX 1660 / RX 580 class hardware. These are project targets, not a verified performance claim.

## Start here

Read these before taking a task:
1. `docs/BUILD_METHOD.md` — implementation principles, build order and definition of done.
2. `docs/VISION.md` — experience and tone.
3. `docs/CANON.md` and `docs/source/STORY.md` — immutable story and ambiguity rules.
4. `docs/ACTS.md` and `data/story/beats.json` — nine-act sequence and action beats.
5. `docs/WORLD_BIBLE.md` and `data/world/` — spatial contract and world data.
6. `docs/ART_BIBLE.md` — visual, audio and Unreality escalation.
7. `docs/ARCHITECTURE.md` — code and scene contracts.
8. `docs/TASKS.md`, `docs/HANDOFF.md`, and relevant `docs/state/` checkpoints — active work.
9. `docs/PRODUCTION_SKELETON.md` — system boundaries, act assembly, quality gates, dependencies, and handoff format.

**Original story:** `docs/source/STORY.md` is verbatim and must never be edited. `bash scripts/tools/story_act.sh N` prints the source passage for an act.

## Run and test

Open `project.godot` in Godot 4.3+ and press F5. Backtick opens a developer-only debug menu. For headless checks run:

```bash
python3 scripts/tools/validate_project_contract.py
bash scripts/tools/run_tests.sh
```

A headless test pass does not prove visual quality. Important lighting, material, camera and atmosphere work must also be inspected in a real window. Record any check that could not be run as **not run**.

The previous gamified prototype is preserved at git tag `v1-gamified`; new work belongs in the existing project tree, not a parallel redesign directory.
