# I've Hung You From the Moon

A first-person psychological-horror **experience game** built in Godot 4.3+ / GDScript. The player physically acts out the original surreal, darkly comic story across nine linear acts, while being free to explore each space at their own pace. The environment gradually unravels around them through a hidden Unreality system—never a visible meter.

**This is not a scoring game.** No score, health, timers, objective list, minimap, or player-facing sanity number. The production priority is detailed, believable spaces; high-quality lighting and materials; sound; environmental interaction; and deliberate surreal escalation.

**Platform:** Windows 10 (64-bit) minimum; Windows 11 supported. Mouse + keyboard. Minimum planning target: quad-core CPU, 8 GB RAM, Vulkan-capable GPU around GTX 960 / RX 470 class, and approximately 6 GB disk. Target 1080p / 60 fps on GTX 1660 / RX 580 class hardware. These are project targets, not a verified performance claim.

## Start here

Read these before taking a task:
1. docs/BUILD_METHOD.md — implementation principles, build order and definition of done.
2. docs/VISION.md — experience and tone.
3. docs/CANON.md and docs/source/STORY.md — immutable story and ambiguity rules.
4. docs/ACTS.md and data/story/beats.json — nine-act sequence and action beats.
5. docs/WORLD_BIBLE.md and data/world/ — spatial contract and world data.
6. docs/ART_BIBLE.md — visual, audio and Unreality escalation.
7. docs/ARCHITECTURE.md — code and scene contracts.
8. data/story/story_map.json and scripts/tools/story_lines.py — source-line-to-beat traceability and verbatim retrieval.
9. docs/WRONGNESS.md and data/wrongness/catalog.json — reusable surreal behaviours and their room instances.
10. data/sensory/spaces.json — each space's sound, surface, wayfinding and state-lighting seed.
11. docs/ASSETS.md and docs/ASSET_REQUESTS.md — asset intake and license rules.
12. docs/ASSET_DOWNLOAD_PACK.md — the smallest useful owner download list.
13. docs/ROADMAP.md and docs/PRODUCTION_SKELETON.md — milestones, system boundaries and acceptance.
14. docs/HUMAN_REVIEW_GATES.md — what requires real human approval.
15. docs/TASKS.md, docs/HANDOFF.md, and relevant docs/state/ checkpoints — active work.

**Original story:** docs/source/STORY.md is verbatim and must never be edited. The existing helper scripts/tools/story_act.sh N prints the source passage for an act in a Bash-capable shell.

## Windows: run and test

Requirements: Windows PowerShell 5.1 or PowerShell 7, Git, and Python 3.10+. The test script looks for Godot 4.3+ in PATH or common install locations. If none is found, it downloads the official Godot 4.3 stable console executable to your user-local cache under %LOCALAPPDATA%\MoonGame\Godot\; it does not require administrator rights.

From the project folder, open PowerShell and run:

\`\`\`powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\tools\run_tests.ps1
\`\`\`

The first run may need internet access to download Godot. To use a specific existing Godot executable, set GODOT_EXE for that PowerShell session:

\`\`\`powershell
$env:GODOT_EXE = "C:\Path\To\Godot_v4.3-stable_win64_console.exe"
.\scripts\tools\run_tests.ps1
\`\`\`

Run only tests whose filenames match a substring, for example:

\`\`\`powershell
.\scripts\tools\run_tests.ps1 -NameFilter audio
\`\`\`

For editing and playing the game, install Godot 4.3 or newer from [the official Godot download page](https://godotengine.org/download/windows/), open project.godot, and press F5. Backtick opens a developer-only debug menu.

## macOS/Linux or Bash-capable environments

The existing Bash test path remains available:

\`\`\`bash
python3 scripts/tools/validate_project_contract.py
bash scripts/tools/run_tests.sh
\`\`\`

## What the checks do—and do not—prove

The preflight checks protected story-source integrity, the nine-act beat structure, indexed world data, and scene presence. The headless suite imports the project and runs each tests/test_*.tscn scene. GitHub Actions also runs the Windows path on pushes and pull requests.

A headless pass does **not** prove visual quality, camera comfort, navigation clarity, performance on your hardware, or sound quality. Important lighting, material, camera and atmosphere work must be inspected in a real window and recorded under docs/HUMAN_REVIEW_GATES.md. Mark any check that could not be run as **NOT RUN**.

## Project boundaries

The previous gamified prototype is preserved at git tag v1-gamified. New work belongs in the existing project tree, not a parallel redesign directory. Preserve docs/source/STORY.md and the October 12, 2026 story/world data unless the project owner explicitly authorizes a change.
