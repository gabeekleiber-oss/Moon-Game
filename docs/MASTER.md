# MASTER MOON DOCUMENT
The single source of truth for how this project runs. If any other doc disagrees about PROCESS, this wins.
(For story/art facts, CANON.md wins. For code contracts, ARCHITECTURE.md wins.)

## 1. What this project is
"I've Hung You From the Moon": a 3D first-person narrative adventure in Godot 4.3 (GDScript), adapted from a surreal, rhyming, darkly comic story.
It is built by up to five Claude accounts working as interchangeable agents, carried between chats by one human. There are no fixed roles.
The git repo (GitHub: gabeekleiber-oss/Moon-Game) is the shared memory. Chats are disposable; the repo is not.

## 2. The five laws
1. **One task per chat.** Work comes from the shared queue (docs/TASKS.md). Agents never edit TASKS.md, HANDOFF.md or DIRECTION.md; scripts do.
2. **Save early, save often.** Every reply presents a small `_start` zip first, then the final zip. Anything not in a presented zip is lost.
3. **Small steps.** Each step leaves the project runnable. Partial work is marked `# TODO(resume): ...`.
4. **The repo wins.** Use what exists (CODE MAP + HANDOFF). Never rebuild another task's system; stub locally and list it under NEEDS FROM OTHER TASKS.
5. **Canon is law.** Never invent "verbatim" story text (write `TODO_VERBATIM`). Never resolve the ambiguity rules in CANON.md.

## 3. THE HUMAN LOOP (the only part you do)
Open Git Bash. Every command starts from the project folder:  `cd ~/Moon-Game`

| Goal | Command | Then |
|------|---------|------|
| Start a new task | `bash scripts/tools/make_context.sh` | Attach the ONE file it shows you (`context\<ID>.md`) to a new chat. Say: `Continue.` |
| Resume a task (chat died, account out of usage, chat too long) | `bash scripts/tools/make_context.sh <ID>` | Same: new chat, attach the file, `Continue.` |
| Apply what the agent produced | `bash scripts/tools/apply_output.sh /c/Users/gabek/Downloads/<zip name>` | Do this for EVERY zip, in the order received. Then tell the chat `next`. |
| Run several accounts at once | Open another Git Bash window, `cd ~/Moon-Game`, run `make_context.sh` again | It hands out a different task each time. |
| Test the game | Open `project.godot` in Godot 4.3+, press F5 | Backtick opens the chapter select. Paste any error into the chat. |

Rules of thumb: attach ONLY the context file, never other docs. Restart the chat about every 10 steps (`make_context.sh <ID>` again).
If a reply forgot the zip, say: `Deliver the zip first, then max 5 lines.`
If Godot shows an error: `Godot error after applying step NN: <paste>. Fix it as one small step and deliver the zip.`
You edit by hand only: the North star and Open questions in docs/DIRECTION.md, and docs/CANON.md if the story needs a ruling.
Needs YOU: the source story text for the verbatim passages; the audio decision (default: procedural sound).

## 4. AGENT PROTOCOL (agents: this is your operating procedure)
Your bundle (context/<ID>.md) is built from the repo moments ago. Trust it.

**Orient.** Read START HERE, then begin on NEXT ACTION immediately. Do not ask the human what to do and do not summarize the project back.

**Each reply, in this order:**
1. Present `<ID>_step_NN_start.zip` FIRST: only your updated checkpoint (`docs/state/<ID>.md`) with NEXT ACTION = what you are doing now, plus notes.
2. Think: what is the most valuable next piece of this task, given the code map, HANDOFF and DIRECTION log? You may rewrite your plan.
3. Build ONE small piece (one scene or script). For longer work, present an extra `_step_NNb.zip` as soon as one file is usable.
4. Present the final `<ID>_step_NN.zip`: every file you created or changed (repo-root-relative paths) + the finished checkpoint.
5. After the zips: at most 5 lines (what changed, how to test, NEXT ACTION). Then STOP and wait for `next`.

**Checkpoint sections you maintain** (docs/state/<ID>.md, under ~40 lines): PLAN, NEXT ACTION, FILES IN FLIGHT, DECISIONS MADE,
NEEDS FROM OTHER TASKS, NOTES FOR DIRECTION (ideas/decisions/concerns for the whole team), PROPOSED TASKS (new work you noticed), HANDOFF NOTE (when DONE).

**Growing the project.** Spot a gap, bug or missing system? Add one line under PROPOSED TASKS: `- (P-<ID>-<n>) description | needs: IDs or - | ch: chapters or - | TODO`.
The apply script queues it for other accounts. Do not build it yourself unless it is part of your task.

**Finishing.** Goal met -> `STATUS: DONE` on line 2 of the checkpoint + a filled HANDOFF NOTE (paths, public API, gotchas). Say what should happen next and propose it.

**Shared files** (`autoload/events.gd`, `autoload/game.gd`, `autoload/chapter_manager.gd`, `project.godot`): minimal appends only; never reformat or reorder.
**Conflicts:** if the CODE MAP lists `*.incoming` files, your FIRST step is to merge each into its original file and delete the `.incoming`.
**Style:** static-typed GDScript, `##` doc comments on every script and public function, new systems in their own folder, scenes runnable standalone (F6), systems talk through the `Events` bus.
Full details: CHAT_RULES.md, CONVENTIONS.md, ARCHITECTURE.md.

## 5. How the machinery works (so failures are understandable)
- `make_context.sh` claims the next TODO task whose dependencies are DONE (TASKS.md: TODO -> IN-PROGRESS), creates its checkpoint if new, commits + pushes the claim,
  then writes `context/<ID>.md`: START HERE, rules, canon, design, chapter text, architecture contracts, task queue, handoffs, your checkpoint, code map, files in flight.
- `apply_output.sh` extracts a zip, copies in new files, 3-way-merges files others also changed (a failed merge keeps the current file and saves the agent's as `<file>.incoming`),
  appends NOTES FOR DIRECTION to docs/DIRECTION.md, queues PROPOSED TASKS, marks a task DONE (and publishes its HANDOFF NOTE) when the checkpoint says `STATUS: DONE`, then commits and pushes.
- Zip names must start with the task ID (`F-01_step_03.zip`, `F-01_step_03_start.zip`). Scripts ignore any zip entry for TASKS.md, HANDOFF.md, or another task's checkpoint.
- A task whose agent vanished stays IN-PROGRESS: anyone can resume it with `make_context.sh <ID>`.

## 6. Troubleshooting
| Symptom | Fix |
|---------|-----|
| `could not pull` / `push failed` | Check internet/GitHub login; run `git push` manually. Work is safe locally. |
| `CONFLICT: <file>` | Nothing is lost. The next chat for that task merges `<file>.incoming` first. |
| `Zip name must start with a task ID` | Rename the zip to `<ID>_step_NN.zip` (e.g. `F-01_step_02.zip`). Browser `(1)` suffixes are fine. |
| `Unknown task` | The ID isn't in docs/TASKS.md. Check spelling (`F-01`, `C-05`, `P-F-01-1`). |
| `No available tasks right now` | Everything is claimed or waiting on dependencies. Finish/resume an IN-PROGRESS task, or wait for a DONE. |
| Agent produced an essay, no zip | Send: `Deliver the zip first, then max 5 lines.` |
| Agent seems lost / contradicts the repo | Chat too long. Run `make_context.sh <ID>` and start a fresh chat. |
| Godot error | Paste it into the same chat with the "Godot error after applying step NN" prompt. |
| Chat died mid-reply | Apply any `_start`/partial zips it did deliver, then `make_context.sh <ID>` and resume in a new chat. |

## 7. Roadmap (milestones; see TASKS.md for the live queue)
- M0 skeleton + 11 chapter stubs + debug select (done)
- M1 core systems (F-01..F-13: dialogue, interaction, HUD, post-fx, cutscene, pause/notepad, moon+eye, audio, props, birds, characters, title) + Ch1-3 vertical slice
- M2 Ch4-7   - M3 Ch8-11   - M4 integration (Z-01), polish and performance (Z-02), export
Tier-1 content that is never cut: canon beats of every chapter, moon with eye, Flea Meter, letter, TV+broom, the drive, dome dialogue, birthday transformation,
lake with "Hello, son", Gronfiser verse, statue-room flea takeover, the fire.

## 8. Changing this document
Only the human edits MASTER.md. An agent that thinks the process should change writes it under NOTES FOR DIRECTION; the human decides.
