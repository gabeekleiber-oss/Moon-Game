extends Node
## Global signal bus. APPEND-ONLY (add signals, never rename/reorder). Group by system. Document in docs/ARCHITECTURE.md.
## Systems talk through this bus so they never need to know about each other.

# --- Player ---
signal player_spawned(player: Node3D)

# --- Acts and story progress ---
## An act scene finished loading and began.
signal act_started(id: int)
## The act's last beat is done (its unlock cue is about to fire).
signal act_completed(id: int)
## The next act became available (the cue is how the world tells the player).
signal act_unlocked(id: int)
## One story beat of an act was completed (see docs/ACTS.md for the beat ids).
signal beat_completed(act: int, beat: String)
## A subtle-but-noticeable "go here next" cue fired in the world (light, sound, a door unlocking...).
signal cue_fired(act: int, cue: String)
signal flag_set(flag_name: String)

# --- Unreality (the hidden insanity value; never shown to the player) ---
## `level` is the smoothed felt value 0..1; `delta` the change since last emit; `reason` a debug string.
signal unreality_changed(level: float, delta: float, reason: String)
## The level crossed into another band (0 ordinary .. 5 ruin). See docs/ART_BIBLE.md.
signal unreality_band_changed(band: int, band_name: String)
## A one-off "wrongness" moment the world should react to (a spike; effects decide how).
signal unreality_spiked(amount: float, reason: String)

# --- Dialogue / narration ---
signal dialogue_started(id: String)
signal dialogue_ended(id: String)
signal caption(who: String, text: String)

# --- UI ---
## A short line of in-world text (an interactable's response, a toast).
signal show_message(text: String)

# --- Interaction ---
## Emitted when the looked-at interactable changes. `target` is null when nothing is focused.
signal interact_focus_changed(target: Node3D)
## Emitted after the player successfully uses `target` (press [E]).
signal interacted(target: Node3D)

# --- Dialogue extras ---
## A dialogue line appeared (full text, before the typewriter finishes).
signal dialogue_line(who: String, text: String)
## The player picked a choice (0-based index) with this text.
signal dialogue_choice_made(index: int, text: String)
## A dialogue node asked for a camera / sfx / emote cue. kind is "cam", "sfx" or "emote".
signal dialogue_cue(kind: String, value: Variant)
## One signal per newly revealed non-space character while a line types out. Audio hooks voice blips here.
signal speaker_blip(who: String, ch: String)

# --- Cutscenes ---
## A cutscene began (Cutscene.play / begin). Player and interaction lock.
signal cutscene_started(id: String)
## A cutscene ended. `skipped` is true if the player held Space to skip it.
signal cutscene_ended(id: String, skipped: bool)

# --- Settings ---
## A setting changed through GameSettings.set_value (key is one of Game.settings' keys).
signal settings_changed(key: String)

# --- Pause ---
## The pause menu opened (true) or closed (false). Audio can duck on this.
signal game_paused(paused: bool)
