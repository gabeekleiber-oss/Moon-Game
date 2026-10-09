# CLAUDE.md - read first, every session

You are one of 5 Claude agents building a Godot 4.3 game ("I've Hung You From the Moon") through this git repo.
**You can run out of tokens at any moment, without warning, mid-message.** The next agent continues from whatever is saved.
So: SAVE CONSTANTLY. Nothing that is not on disk and in git is real.

## Start of session (the resume briefing prints automatically; if not, run `bash scripts/tools/resume.sh`)
1. If no role is set: ask the human, then `bash scripts/tools/setup_role.sh <lead|assets|slice|mansion|dream>`.
2. Read ONLY what you need (saves tokens):
   - Everyone: this file, docs/CANON.md, your own checkpoint, your role's rows in docs/ROLES.md and docs/TASKS.md.
   - Chapter agents: just YOUR chapters in docs/CHAPTERS.md, plus the DESIGN.md sections "Core systems" and "Palettes".
   - Read an ARCHITECTURE.md section only when you need that system (dialogue, interactables, mapping table).
   - Lead only: read everything.
3. Read YOUR checkpoint `docs/state/<role>.md` and continue at its **NEXT ACTION**.
4. The previous agent may have been cut off mid-file. Open the last files it touched and check they are complete and valid before building on them.

## The save protocol (non-negotiable)
- **Plan first, in the checkpoint.** Before coding a task, write the step list into `docs/state/<role>.md` (steps small enough to finish in ~10 minutes each).
- **Update the checkpoint once per STEP (not per tool call)** (tick the step, rewrite NEXT ACTION in one concrete sentence, list files in flight). Do this BEFORE starting the next step. Keep the whole checkpoint under ~40 lines: delete old LOG lines and finished plan steps rather than accumulating them.
- **Write files in small pieces.** Create a skeleton that runs first (even if empty/stubbed), then fill in functions one at a time. Never write a 500-line file in one go: a cut-off write loses everything in it.
- **Leave the project in a runnable state** after each step. If you must leave something half-done, add `# TODO(resume): <what's missing>` at the exact spot.
- Autosave runs after every edit (commits + pushes to branch `wip/<role>`). You don't need to commit manually, but when a whole TASK is done run `bash scripts/tools/finish_task.sh "message"` to publish to main, then tick it in docs/TASKS.md and add a docs/HANDOFF.md entry.
- Prefer many small tool calls over one giant one.

## Working rules
- Edit only files your role owns (docs/ROLES.md). Shared files are append-only.
- CANON.md is law; ambiguity rules are never resolved. Never invent "verbatim" story text: mark `TODO_VERBATIM` and ask the human.
- Static-typed GDScript, scenes runnable standalone, talk through the `Events` bus.
- No jump scares / gore. Tone: sincere comedy over real grief.

## If you are stuck or something is blocked
Write it in the checkpoint under BLOCKERS and in docs/HANDOFF.md ("Questions for Lead"), then move to the next unblocked task.

## Taking over another role's stalled work
`bash scripts/tools/takeover.sh <role>` - then read that role's checkpoint and continue. Add a line to HANDOFF noting the takeover.
