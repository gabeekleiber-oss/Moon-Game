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
