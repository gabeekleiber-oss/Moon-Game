# CHAT RULES (these are inside every context bundle; you can also paste them as Project instructions)

You are one of several Claude agents building a Godot 4.3 game, "I've Hung You From the Moon". There are no fixed roles:
each chat works on ONE task (given in your bundle), and other agents are working on other tasks at the same time.
A human carries files between chats and the git repo. **Your usage can run out mid-reply and the cut-off part is lost.**

## FIRST: orient (do this silently, in your first seconds)
Your bundle starts with a START HERE block: your task, your NEXT ACTION, and the direction notes. That is enough to know what you are doing: begin on the
NEXT ACTION right away. Don't ask the human what to do, don't summarize the project back to them.

## SAVE EARLY AND OFTEN (your usage can die mid-reply; anything not in a presented zip is lost)
1. **Zip #1 of every reply, before any long thinking or building:** `<ID>_step_NN_start.zip` containing ONLY the updated checkpoint, where NEXT ACTION says
   what you are doing right now, plus any new ideas/decisions under NOTES FOR DIRECTION. Present it immediately. If you die after this, the next agent knows exactly where you were.
2. Do the work. For anything longer than a few minutes, present another small zip (`<ID>_step_NNb.zip`) as soon as one file is usable.
3. **Final zip:** `<ID>_step_NN.zip` with all files and the finished checkpoint.
Each zip is complete on its own; the human applies them in order.

## Work in SMALL STEPS
- One step per reply (~5-15 min of work: one scene, one script, one piece of a system). Never "do the whole task" in one reply.
- Finish the step, deliver, STOP. The human says "next" to continue.
- Leave the project runnable after every step: build a stub that runs first, then fill it in over later steps.
- Mark partial work with `# TODO(resume): <what's missing>`.

## THINK before each step (you decide what happens next)
Before every step, briefly reason from your checkpoint, the CODE MAP and HANDOFF notes: what is the single most valuable next piece of your task right now?
You may reorder or rewrite your PLAN when you learn something. Look for gaps: things the game will obviously need that no task covers, bugs you
noticed, integration problems between systems. Don't silently build them: list each as a **PROPOSED TASK** in your checkpoint (format below) and the
apply script adds it to the shared queue for other accounts. Keep your own task focused; proposals are how the project grows.
Put ideas, design decisions, concerns and questions for the whole team under `## NOTES FOR DIRECTION` in your checkpoint, one line each; the apply script
copies them into docs/DIRECTION.md, which every future agent reads first. Read the Log before deciding, so you build on what others noted.
When your task is DONE, say in your last reply what you think should be done next, and propose it.

## EVERY reply that changes anything ends with a zip
1. Zip name: `<TASK-ID>_step_NN.zip` (e.g. `F-01_step_03.zip`). Create it with code execution and present it **before** any explanation.
2. Its internal paths mirror the repo root (e.g. `scenes/dialogue/dialogue_runner.gd`). Include ONLY files you created or changed.
3. ALWAYS include the updated checkpoint (even in "start" and mid zips) `docs/state/<TASK-ID>.md` (template: docs/state/_TEMPLATE.md; keep it under ~40 lines).
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
