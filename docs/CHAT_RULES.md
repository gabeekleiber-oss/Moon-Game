# CHAT RULES (paste as Project instructions, or as the first message of every chat)

You are one of 5 Claude agents building a Godot 4.3 game, "I've Hung You From the Moon". You work in a normal chat.
A human carries your files into a git repo. **Your usage can run out mid-reply, and the cut-off part is lost.** So:

## Work in SMALL STEPS
- One step per reply (~5-15 min of work; one scene, one script, one system piece). Never "build the whole chapter" in one reply.
- Finish the step, deliver it, STOP. The human says "next" to continue.
- Leave the project runnable after every step. Build a stub that runs first, then fill it in over later steps.
- Mark anything partial with `# TODO(resume): <what's missing>`.

## EVERY reply that changes anything MUST end with delivery
1. **A zip** (create it with code execution) whose internal paths mirror the repo root, containing ONLY the files you created/changed, including the updated checkpoint `docs/state/<role>.md`. Name it `<role>_step_NN.zip`. Deliver it with the file-present tool.
2. **Deliver BEFORE you explain.** Put the zip first, then at most 5 lines of text: what changed, how to test it, the NEXT ACTION. No long essays.
3. Keep the checkpoint under ~40 lines (use the template in docs/state/_TEMPLATE.md): current task, small plan with ticks, NEXT ACTION (one concrete sentence), files in flight, decisions, blockers.
If you are about to do something long, say "Delivering step first" and deliver a smaller piece rather than risk losing it.

## Context you are given
The human pastes/attaches a context bundle: these rules, CANON, your role + tasks, your chapters, your checkpoint, your files in flight.
Do not ask for the whole repo. If you need a file you weren't given, ask for that one file by path.
The previous agent may have been cut off mid-file: first check its last files are complete and valid.

## Rules
- Edit only files your role owns (ROLES.md). Need something from another role? Put it in your checkpoint under BLOCKERS and the human will relay it; use a placeholder.
- CANON.md is law; ambiguity rules are never resolved. Never invent "verbatim" story text: mark `TODO_VERBATIM`.
- Static-typed GDScript; scenes run standalone; talk through the `Events` bus; build complex scenes in code or keep .tscn hand-edits minimal.
- No jump scares or gore. Tone: sincere comedy over real grief.
- When a whole TASK is done, say so, tick it in TASKS.md (append-only edit) and add a HANDOFF.md entry in the same zip.
