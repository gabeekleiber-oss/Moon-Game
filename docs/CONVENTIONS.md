# CONVENTIONS

## Naming
Files/folders `snake_case`; nodes `PascalCase`; classes `PascalCase` (`class_name`); vars/funcs `snake_case`; consts `UPPER_SNAKE`;
signals past-tense; private members leading underscore. Act folders `actNN_name`.

## GDScript
Static typing everywhere. `##` doc comment atop each script (what it is + how to use it: the CODE MAP shows these to other agents).
`@export` for tunables. Gameplay numbers in a const block or Resource.

## Working together without roles
1. New systems live in their own folder (`scenes/dialogue/`, `scenes/world/`, `scenes/fx/`...). Acts live in `scenes/acts/actNN_*/`; rooms and props for a location live in `scenes/world/<place>/`.
2. Shared files (events.gd, game.gd, acts.gd, unreality.gd, project.godot): minimal edits only; append, don't reorder or reformat.
3. Reuse other agents' APIs (see CODE MAP + HANDOFF); don't duplicate systems.
4. Public functions and signals get `##` doc comments so the code map is useful.
5. Leave the project runnable after every step; mark partials `# TODO(resume):`.

## Content rules
- CANON.md is law; ambiguity rules never resolved. Never fabricate verbatim story text (`TODO_VERBATIM`; the source is docs/source/STORY.md).
- No visible meters, scores, health, HUD or objective text. Hints are in-world (light, sound, a door standing open).
- Interactables are quiet: a short in-world line (`message`) at most, in the narrator's voice; never marked "canon choice" in UI.
- Everything that moves multiplies `Unreality.motion_scale()`; Reduced Motion removes sway, wobble, specks, chroma, flicker. No flashing >3/s.
- Real PBR assets only (CC0 first); every external asset has a line in assets/LICENSES.md; every scene must still run with a code-built `# PLACEHOLDER` if the asset is missing.
- Tests prove logic; looks need a real-window check: write "unverified in a real window" when you could not.

## Done = no debugger errors; scene runs standalone; checkpoint STATUS: DONE with HANDOFF NOTE.
