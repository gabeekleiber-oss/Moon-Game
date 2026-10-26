class_name GameSettings
extends RefCounted
## Loads, validates, saves and APPLIES the player settings stored in `Game.settings`. (F-06)
##
## Keys: quality ("auto"|"high"|"medium"|"low"), volume (0..1), sensitivity (radians per mouse pixel),
## reduced_motion (bool), assist (bool). Everything goes through `set_value` so it is clamped, applied, saved to
## user://settings.json and announced with Events.settings_changed(key):
##     GameSettings.set_value("volume", 0.5)
## PauseMenu loads and applies the saved file at boot. Other systems only READ Game.settings (they already do).
## Effects: volume -> Master audio bus; quality -> 3D resolution scale + shadow atlas sizes (PostFX also switches
## its pass off on "low"); sensitivity -> read by player.gd; reduced_motion -> read by HUD/PostFX/Cutscene/outline;
## assist -> read by InteractionRay (longer reach) and available to any mechanic via Game.settings["assist"].

## Where settings are stored. Tests point this at a scratch file.
static var path: String = "user://settings.json"

const DEFAULTS := {"quality": "auto", "volume": 0.8, "sensitivity": 0.0022, "reduced_motion": false, "assist": false}
const QUALITY_VALUES := ["auto", "high", "medium", "low"]
const SENSITIVITY_MIN := 0.0008
const SENSITIVITY_MAX := 0.006
## 3D resolution scale per quality level (Auto = full size until an adaptive step-down exists).
const SCALE_BY_QUALITY := {"auto": 1.0, "high": 1.0, "medium": 0.85, "low": 0.67}
const SHADOW_ATLAS_BY_QUALITY := {"auto": 2048, "high": 4096, "medium": 2048, "low": 1024}


## Returns `value` coerced and clamped into the legal range for `key`; unknown keys return null.
static func sanitize(key: String, value: Variant) -> Variant:
	match key:
		"quality":
			return str(value) if QUALITY_VALUES.has(str(value)) else DEFAULTS["quality"]
		"volume":
			return clampf(float(value), 0.0, 1.0) if (value is float or value is int) else DEFAULTS["volume"]
		"sensitivity":
			return clampf(float(value), SENSITIVITY_MIN, SENSITIVITY_MAX) if (value is float or value is int) else DEFAULTS["sensitivity"]
		"reduced_motion", "assist":
			return bool(value) if value is bool else DEFAULTS[key]
	return null


## Validates and stores one setting, applies it, saves the file and emits Events.settings_changed.
static func set_value(key: String, value: Variant) -> void:
	var clean: Variant = sanitize(key, value)
	if clean == null:
		push_warning("GameSettings: unknown setting '%s'" % key)
		return
	Game.settings[key] = clean
	apply(key)
	save()
	Events.settings_changed.emit(key)


## Restores every setting to its default (applied, saved, announced).
static func reset_to_defaults() -> void:
	for k in DEFAULTS:
		Game.settings[k] = DEFAULTS[k]
	apply_all()
	save()
	for k in DEFAULTS:
		Events.settings_changed.emit(k)


## Reads the settings file into Game.settings (bad or missing values keep their defaults) and applies everything.
static func load_and_apply() -> void:
	for k in DEFAULTS:
		Game.settings[k] = DEFAULTS[k]
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			for k in DEFAULTS:
				if (parsed as Dictionary).has(k):
					Game.settings[k] = sanitize(k, (parsed as Dictionary)[k])
		else:
			push_warning("GameSettings: %s is not valid JSON; using defaults." % path)
	apply_all()
	if not FileAccess.file_exists(path):
		save()  # First run: persist validated defaults.


## Writes Game.settings to disk. Returns false if the file could not be written.
static func save() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("GameSettings: cannot write %s" % path)
		return false
	var out := {}
	for k in DEFAULTS:
		out[k] = Game.settings.get(k, DEFAULTS[k])
	f.store_string(JSON.stringify(out, "\t"))
	return true


## Applies every setting to the engine.
static func apply_all() -> void:
	for k in DEFAULTS:
		apply(k)


## Applies one setting to the engine (volume, quality); the rest are read on demand by their systems.
static func apply(key: String) -> void:
	match key:
		"volume":
			var v: float = float(Game.settings.get("volume", 0.8))
			var bus := AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(bus, v <= 0.001)
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.001)))
		"quality":
			var q := str(Game.settings.get("quality", "auto"))
			var root := (Engine.get_main_loop() as SceneTree).root
			root.scaling_3d_scale = float(SCALE_BY_QUALITY.get(q, 1.0))
			var atlas: int = int(SHADOW_ATLAS_BY_QUALITY.get(q, 2048))
			root.positional_shadow_atlas_size = atlas
			RenderingServer.directional_shadow_atlas_set_size(atlas, true)
		"reduced_motion", "assist", "sensitivity":
			pass
