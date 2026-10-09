# HANDOFF (newest first). Written by scripts from finished tasks' HANDOFF NOTEs. Do not edit by hand.


<!-- done:F-02 -->
## F-02 done (2026-10-09)
- Make an interactable: add `Interactable` (scenes/interaction/interactable.gd, class_name Interactable) + CollisionShape3D + meshes; set `prompt`, `message` (funny reply), `once`, `range` (default 2.4), `set_flag_on_use`.
- React: connect its `used(player)` signal, or extend and override `_on_use(player)`. Toggle with `enabled`; `reset_use()` re-arms a `once` object.
- Events: `Events.interact_focus_changed(target|null)`, `Events.interacted(target)`. Non-Interactable nodes work if in group `interactable`, layer 4, with prompt/range/can_use()/use().
- The player already gets an InteractionRay (+ reticle/prompt HUD) on its Camera3D from player.gd; nothing to add per chapter.
- Gotcha: the ray ignores interactables while a dialogue runs (dialogue_started/ended) and while the mouse is not captured.
## v0.4 - setup
Switched to a flat shared task queue (no roles). Existing: Game state (Flea, Hearts, flags, Notepad), ChapterManager, DebugMenu (backtick),
ChapterBase (`scripts/chapter_base.gd`), 11 chapter stubs (press N to advance in debug), first-person player (`scenes/player/`), Events bus.
