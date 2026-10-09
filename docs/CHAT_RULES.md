# CHAT RULES (these are inside every context bundle; you can also paste them as Project instructions)

You are one of several Claude agents building a Godot 4.3 game, "I've Hung You From the Moon". There are no fixed roles:
each chat works on ONE task (given in your bundle), and other agents are working on other tasks at the same time.
A human carries files between chats and the git repo. **Your usage can run out mid-reply and the cut-off part is lost.**

## Work in SMALL STEPS
- One step per reply (~5-15 min of work: one scene, one script, one piece of a system). Never "do the whole task" in one reply.
- Finish the step, deliver, STOP. The human says "next" to continue.
- Leave the project runnable after every step: build a stub that runs first, then fill it in over later steps.
- Mark partial work with `# TODO(resume): <what's missing>`.

## EVERY reply that changes anything ends with a zip
1. Zip name: `<TASK-ID>_step_NN.zip` (e.g. `F-01_step_03.zip`). Create it with code execution and present it **before** any explanation.
2. Its internal paths mirror the repo root (e.g. `scenes/dialogue/dialogue_runner.gd`). Include ONLY files you created or changed.
3. ALWAYS include the updated checkpoint `docs/state/<TASK-ID>.md` (template: docs/state/_TEMPLATE.md; keep it under ~40 lines).
4. NEVER include `docs/TASKS.md` or `docs/HANDOFF.md`: scripts update those. NEVER include another task's checkpoint.
5. After the zip: at most 5 lines: what changed, how to test it, the NEXT ACTION.
If a step is getting long, deliver a smaller piece first.

## Building on other agents' work (read this carefully)
- Your bundle has a **CODE MAP** (every script's public functions/signals) and the latest HANDOFF notes. Use existing systems; don't re-implement them.
  If you need a file's full contents, ask for it by path.
- If something you need doesn't exist yet (its task isn't DONE), make a tiny local stub inside your own task's folder and list it under
  "NEEDS FROM OTHER TASKS" in your checkpoint. Don't build the other task for them.
- Put new work in its own folder (e.g. `scenes/dialogue/`, `scenes/hud/`, `scenes/props/`, `scenes/chapters/chNN_*/`).
- Shared files (`autoload/events.gd`, `autoload/game.gd`, `autoload/chapter_manager.gd`, `project.godot`): change them MINIMALLY. Add a signal or a
  few lines; never reformat, reorder or rewrite. The apply script 3-way-merges your change with other agents' changes.
- If you find files named `*.incoming` in the CODE MAP, a merge conflict happened: your first step is to merge each into its original and delete the `.incoming`.
- Fix bugs you find in others' code only if small and necessary; mention it in your checkpoint DECISIONS.

## Finishing
When the task's goal is fully met: set `STATUS: DONE` on line 2 of your checkpoint and fill in HANDOFF NOTE (paths, how to call your API, gotchas).
The apply script then marks the task DONE and publishes your note to everyone else.

## Content rules
- docs/CANON.md is law; the ambiguity rules are never resolved. Never invent "verbatim" story text: write `TODO_VERBATIM`.
- Static-typed GDScript; scenes run standalone (F6); systems talk via the `Events` bus. Prefer building complex scenes in code over fragile hand-written .tscn.
- No jump scares or gore. Tone: sincere comedy over real grief. No real songs/lyrics.
