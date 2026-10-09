extends Node
## Global signal bus. APPEND-ONLY. Group by system. Document in docs/ARCHITECTURE.md.

# --- Player ---
signal player_spawned(player: Node3D)
signal player_died

# --- Chapters ---
signal chapter_started(id: int)
signal chapter_completed(id: int)

# --- Meters / state ---
signal flea_changed(value: float, delta: float, reason: String)
signal heart_changed(who: String, value: int, delta: int)
signal flag_set(flag_name: String)
signal notepad_item_added(item: Dictionary)

# --- Dialogue / narration ---
signal dialogue_started(id: String)
signal dialogue_ended(id: String)
signal caption(who: String, text: String)
signal objective_set(text: String)

# --- UI ---
signal show_message(text: String)

# --- Interaction (F-02) ---
## Emitted when the looked-at interactable changes. `target` is null when nothing is focused.
signal interact_focus_changed(target: Node3D)
## Emitted after the player successfully uses `target` (press [E]).
signal interacted(target: Node3D)

# --- Dialogue extras (F-01) ---
## A dialogue line appeared (full text, before the typewriter finishes).
signal dialogue_line(who: String, text: String)
## The player picked a choice (0-based index) with this text.
signal dialogue_choice_made(index: int, text: String)
## A dialogue node asked for a camera / sfx / emote cue. kind is "cam", "sfx" or "emote".
signal dialogue_cue(kind: String, value: Variant)
## One signal per newly revealed non-space character while a line types out. Audio hooks voice blips here.
signal speaker_blip(who: String, ch: String)
