# WORKFLOW (regular Claude chat; no roles)
> The master document is docs/MASTER.md. If this file disagrees with it, MASTER.md wins.

## The idea
Every account is interchangeable. Work is a shared queue of TASKS (docs/TASKS.md). Each chat does ONE task in small steps, delivering a zip
each step. You (the human) apply zips to the repo with one command; the repo is the shared memory. If an account runs out of usage, the
unfinished task stays IN-PROGRESS with a checkpoint, and any account can resume it.

## One-time setup
1. Git, Godot 4.3+, GitHub repo (done: Moon-Game). Work in the repo folder; use **Git Bash** for the scripts.
2. On every Claude account: Settings -> enable **Code execution and file creation**.

## The loop
**Start a task**
1. Git Bash, in the repo folder: `bash scripts/tools/make_context.sh`
   (claims the next available task, prints its ID, writes `context/<ID>.md`).
2. New chat on any account with usage left. Attach `context/<ID>.md`. Say: **Continue.**
3. Agent replies with `<ID>_step_NN.zip` + a few lines.
**Apply**
4. `bash scripts/tools/apply_output.sh /c/Users/gabek/Downloads/<ID>_step_NN.zip`
   (merges, updates status, commits, pushes; tells you if there's a conflict)
5. Test in Godot if you want. Reply **next**, or paste the Godot error.
**When the chat dies / gets long / account runs out**
6. `bash scripts/tools/make_context.sh <ID>` (same ID) -> new chat on any account -> **Continue.**
**Running several accounts at once**
Open another Git Bash window, run `make_context.sh` again: it hands out the next *different* task. Apply zips in any order.
Foundation tasks (F-xx) have no dependencies, so 5 accounts can start on 5 of them immediately.

## Shared notebook
`docs/DIRECTION.md` is the team's shared direction file. Agents write ideas/decisions/concerns in their checkpoint; `apply_output.sh` appends them to the Log, and every
new context bundle opens with the North star + latest notes. You edit the North star and the "Open questions" there by hand.
Each reply now presents a small `_start` zip FIRST (saves where the agent is), then the final zip. Apply every zip you get, in order.

## Rules of thumb
- One task per chat; restart the chat every ~10 steps (history is re-read every message).
- Tasks marked DONE publish a HANDOFF note that every later bundle includes, plus a code map of the whole repo, so new agents see what exists.
- Shared files (events.gd, game.gd...) are 3-way merged automatically. A conflict leaves a `*.incoming` file; the next chat for that task merges it first.
- Stuck tasks: if a task stays IN-PROGRESS with nobody working on it, just resume it with its ID.
- Agents never edit TASKS.md or HANDOFF.md; the scripts do.
