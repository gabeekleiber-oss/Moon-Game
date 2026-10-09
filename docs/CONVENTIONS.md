# CONVENTIONS

## Naming
Files/folders `snake_case`; nodes `PascalCase`; classes `PascalCase` (`class_name`); vars/funcs `snake_case`; consts `UPPER_SNAKE`;
signals past-tense; private members leading underscore. Chapter folders `chNN_name`.

## GDScript
Static typing everywhere. `##` doc comment atop each script (what it is + how to use it: the CODE MAP shows these to other agents).
`@export` for tunables. Gameplay numbers in a const block or Resource.

## Working together without roles
1. New systems live in their own folder (`scenes/dialogue/`, `scenes/hud/`, `scenes/props/`...). Chapters live in `scenes/chapters/chNN_*/`.
2. Shared files (events.gd, game.gd, chapter_manager.gd, project.godot): minimal edits only; append, don't reorder or reformat.
3. Reuse other agents' APIs (see CODE MAP + HANDOFF); don't duplicate systems.
4. Public functions and signals get `##` doc comments so the code map is useful.
5. Leave the project runnable after every step; mark partials `# TODO(resume):`.

## Content rules
- CANON.md is law; ambiguity rules never resolved. Never fabricate verbatim story text (`TODO_VERBATIM`).
- No real songs/lyrics; Sound of Music scene is a pastiche. Original rhymes only.
- Every interactable gets a funny response. Canon choice is never marked in UI.
- Reduced Motion disables shake, bob, chroma, FOV breathing, edge-flea crawl. No flashing >3/s.

## Done = no debugger errors; scene runs standalone; checkpoint STATUS: DONE with HANDOFF NOTE.
