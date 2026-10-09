# You are an agent on "I've Hung You From the Moon" (Godot 4.3, GDScript)
Several Claude accounts build this game in parallel through this git repo. The repo is the only shared memory. Your usage can end at any moment:
**anything you have not saved with `save.sh` is lost.** There are no zips in this mode.

## Do this immediately, without asking the human anything
1. `bash scripts/tools/start.sh`  (or `start.sh <ID>` if the human named a task)  -> it claims (or resumes) a task and tells you which file to read.
2. Read `context/<ID>.md` fully (rules, canon, design, direction notes, code map, your checkpoint). Ignore its zip instructions: in this mode you save with `save.sh`.
3. Open `docs/state/<ID>.md` (your checkpoint). If NEXT ACTION is a placeholder, write a real 4-6 step PLAN and a concrete NEXT ACTION, then `bash scripts/tools/save.sh "plan"`.

## Work loop (repeat)
- Decide the single most valuable next small piece (one scene or script). Think about gaps, bugs and ideas as you go.
- Before starting it: put what you are about to do in NEXT ACTION in your checkpoint and `bash scripts/tools/save.sh "starting: <piece>"`.
- Build it. Keep the project runnable. Mark partials `# TODO(resume): ...`.
- After it works (or every ~10 minutes of work): update the checkpoint (FILES IN FLIGHT, DECISIONS, NEXT ACTION), then `bash scripts/tools/save.sh "<what changed>"`.
- Ideas/decisions/concerns for the whole team: one line each under `## NOTES FOR DIRECTION` in your checkpoint (save.sh copies them to docs/DIRECTION.md).
- New work you notice that isn't your task: one line under `## PROPOSED TASKS` using the exact format in docs/state/_TEMPLATE.md (save.sh queues it).
- Task finished: set `STATUS: DONE` on line 2 of the checkpoint, fill HANDOFF NOTE, `save.sh "done"`, then run `start.sh` again and take the next task.
  Keep going task after task until usage ends or start.sh prints NO_TASKS.

## Hard rules
- NEVER hand-edit `docs/TASKS.md`, `docs/HANDOFF.md`, `docs/DIRECTION.md` (scripts do), another task's checkpoint, or docs/MASTER.md / docs/CANON.md.
- Shared files (`autoload/events.gd`, `game.gd`, `chapter_manager.gd`, `project.godot`): minimal appends only. Use what exists (CODE MAP); put new systems in their own folder.
- `docs/CANON.md` is law; never invent verbatim story text (write `TODO_VERBATIM`); never resolve the ambiguity rules. No jump scares or gore; no real songs/lyrics.
- If `save.sh` reports a merge conflict, resolve it keeping both sides' intent, `git add`, `GIT_EDITOR=true git rebase --continue`, save again.
- Static-typed GDScript, `##` doc comments, scenes runnable standalone, systems talk through the `Events` bus. Details: docs/MASTER.md, docs/CONVENTIONS.md, docs/ARCHITECTURE.md.
- Final replies to the human: at most 5 lines.
