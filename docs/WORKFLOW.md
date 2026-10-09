# WORKFLOW (regular Claude chat, not Claude Code)

## The idea
Agents can run out of usage at any moment and lose the unfinished part of a reply. So:
1. **Each reply = one small step, delivered as a zip first.** Worst case you lose one small step.
2. **Everything an agent knows is in files** (checkpoint + repo), never only in the chat.
3. **A new chat resumes from a context bundle** built by one command. Any account can pick up any role.

## One-time setup
1. Install Git + Godot 4.3+. Create a private GitHub repo, unzip game-project, `git init -b main`, commit, add remote, push.
2. In each Claude account: Settings -> enable **Code execution and file creation** (agents need it to make zips).
3. (Recommended) In each account create a **Project** per role, e.g. "Moon - slice". Put `docs/CHAT_RULES.md` in Project instructions and
   upload the stable docs (DESIGN, CANON, CHAPTERS, ARCHITECTURE, CONVENTIONS, ROLES) as Project knowledge. Then each chat only needs
   the small per-chat bundle. (If your plan lacks Projects, skip this: the bundle from make_context.sh already includes what's needed.)

## The loop (you are the courier)
1. `scripts/tools/make_context.sh <role>` -> creates `context/<role>_context.md`.
2. New chat (in that role's Project, on whichever account has usage left). Attach the bundle. Say: **"You are the <role> agent. Continue."**
3. Agent delivers `<role>_step_NN.zip` + a few lines. Download it.
4. `scripts/tools/apply_output.sh ~/Downloads/<role>_step_NN.zip <role>` -> unpacks, commits, pushes.
5. Test in Godot if you like. Tell the agent **"next"** (or paste an error message / Godot output).
6. Repeat 3-5. When the agent runs out of usage, or the chat gets long: go to step 1 and start a fresh chat.

## Keep chats short
Chat history is re-read on every message, so long chats burn usage fast. Start a fresh chat every ~10 steps or per task. The checkpoint +
bundle make restarts cheap.

## Running 5 agents
Agents never edit the same files (ROLES.md), so you can run them in parallel on different accounts and apply their zips in any order.
Cross-role requests go in checkpoints under BLOCKERS: you relay them (add a line to TASKS.md for the other role).
Lead goes first (dialogue runner, interaction, HUD); the others stub those until they land.

## If an agent gets cut off mid-reply
The reply is lost; nothing was applied. Run make_context.sh again and start a new chat: the last applied checkpoint says what's next.

## Optional: Claude Code
If you later get Claude Code, CLAUDE.md + .claude/settings.json + the other scripts in scripts/tools give full autosave and auto-resume.
