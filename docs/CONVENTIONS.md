# CONVENTIONS

## Naming
Files/folders `snake_case`; nodes `PascalCase`; classes `PascalCase` (`class_name`); vars/funcs `snake_case`; consts `UPPER_SNAKE`;
signals past-tense; private members leading underscore. Chapter folders `chNN_name`.

## GDScript
Static typing everywhere. `##` doc comment atop each script (purpose + owner role). `@export` for tunables. Put gameplay numbers
in a const block or Resource, not scattered literals.

## Merge safety (5 accounts)
1. One owner per file (ROLES.md). 2. Shared files append-only. 3. Never hand-edit another role's .tscn; request via TASKS.md.
4. Small, frequent commits: `[role] message`. 5. Pull/rebase before starting and pushing.
6. Prefer building complex scenes by script (`_ready()` construction) or in-editor over fragile hand-written .tscn.

## Content rules
- CANON.md is law. Ambiguity rules are never resolved.
- Never fabricate verbatim story text. Use `TODO_VERBATIM` markers.
- No real songs/lyrics; Sound of Music scene is a pastiche. Original rhyming lines only.
- Every interactable gets a funny response. Canon choice is never marked in UI.
- Reduced Motion setting must disable shake, bob, chroma, FOV breathing, edge-flea crawl. No flashing >3/s.

## Definition of done
No errors/warnings in debugger; scene runs standalone; chapter's canon beat completes via `complete()`; TASKS + HANDOFF updated.

## Resumability (see CLAUDE.md, docs/WORKFLOW.md)
- Update docs/state/<role>.md after every step. Write files in small pieces. Leave project runnable. Mark partials with `# TODO(resume):`.
