extends Node
## Autoload `Audio`: audio buses, sound-effect playback and reverb. (F-08)
##
## Buses (all send to Master, which GameSettings controls): Music, SFX, Amb, Voice. SFX, Amb and Voice each carry a reverb
## effect that is dry until `set_reverb()` is called.
## API:
##   Audio.play_sfx("pickup", -3.0, 1.1)                 non-positional one-shot (UI, pickups); returns the player
##   Audio.play_sfx_at("thud", Vector3(2, 0, 4))          positional one-shot in the current scene
##   Audio.play_stream(stream, "Amb", -6.0)               any stream on any bus (music/ambience tasks use this)
##   Audio.set_reverb("dome")                             "none" | "room" | "hall" | "dome" | "cave"
##   Audio.set_bus_volume("Music", 0.5)                   linear 0..1
##   Audio.blip("elsa_ray", "H")                          one voice blip (done automatically from Events.speaker_blip)
##   Audio.duck(-8.0) / Audio.unduck()                    dip Music and Amb under speech (automatic during dialogue)
## Automatic reactions: dialogue ducking, muffled Music/Amb while paused, a low sting on unreality spikes,
## a click on interact, and reverb reset to "none" when an act starts.
## Unreality audio (Events.unreality_changed): from 0.25 quiet whispers drift in at ever shorter intervals; from 0.5 every voice blip
## is doubled a little flat, as if a second speaker were a beat behind.
## Dialogue `sfx` cues (Events.dialogue_cue("sfx", name)) play the named recipe automatically.
## Sound names come from SfxRecipesScript.NAMES. Works while the tree is paused (PROCESS_MODE_ALWAYS).

const SfxRecipesScript = preload("res://scenes/audio/sfx_recipes.gd")
const SynthScript = preload("res://scenes/audio/synth.gd")
const VoiceProfilesScript = preload("res://scenes/audio/voice_profiles.gd")
const BUS_NAMES: Array[String] = ["Music", "SFX", "Amb", "Voice"]
const REVERB_BUSES: Array[String] = ["SFX", "Amb", "Voice"]
const POOL_SIZE := 12
const WHISPER_FROM := 0.25      # Unreality level where whispers begin
const DOUBLE_VOICE_FROM := 0.5  # ... and where voice blips get a second, flat double
## How far Music/Amb dip while someone is talking, and the lowpass cutoffs (Hz) for open / paused.
const DIALOGUE_DUCK_DB := -8.0
const CUTOFF_OPEN := 20500.0
const CUTOFF_PAUSED := 900.0
## preset -> [wet, room_size, damping]
const REVERB_PRESETS := {
	"none": [0.0, 0.5, 0.5],
	"room": [0.12, 0.3, 0.6],
	"hall": [0.25, 0.7, 0.4],
	"dome": [0.35, 0.9, 0.3],
	"cave": [0.45, 0.8, 0.2],
}

var _pool: Array[AudioStreamPlayer] = []
var _next_steal: int = 0
var _reverbs: Array[AudioEffectReverb] = []
var _reverb_preset: String = "none"
var _blip_player: AudioStreamPlayer
var _blip_streams: Dictionary = {}
var _blip_counter: int = 0
var _blip_who: String = ""
var _duckers: Array[AudioEffectAmplify] = []
var _lowpasses: Array[AudioEffectLowPassFilter] = []
var _duck_db: float = 0.0
var _duck_tween: Tween
var _last_ms: Dictionary = {}
var _unreality: float = 0.0
var _blip_double: AudioStreamPlayer
var _whisper_left: float = 40.0
var _whisper_rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "Audio"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_setup_buses()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_blip_player = AudioStreamPlayer.new()
	_blip_player.bus = "Voice"
	add_child(_blip_player)
	_blip_double = AudioStreamPlayer.new()
	_blip_double.bus = "Voice"
	add_child(_blip_double)
	_whisper_rng.seed = 90210
	Events.unreality_changed.connect(func(level: float, _d: float, _r: String) -> void: set_unreality(level))
	Events.speaker_blip.connect(blip)
	Events.dialogue_cue.connect(_on_dialogue_cue)
	Events.dialogue_started.connect(func(_id: String) -> void: duck(DIALOGUE_DUCK_DB))
	Events.dialogue_ended.connect(func(_id: String) -> void: unduck())
	Events.game_paused.connect(_on_paused)
	Events.unreality_spiked.connect(_on_unreal_spike)
	Events.interacted.connect(func(_t: Node3D) -> void: play_sfx("click", -8.0))
	Events.act_started.connect(func(_id: int) -> void: set_reverb("none"))


## Plays a named recipe once, non-positionally. Returns the player (null for an unknown name).
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0, bus: String = "SFX") -> AudioStreamPlayer:
	var s := SfxRecipesScript.get_stream(sfx_name)
	if s == null:
		return null
	return play_stream(s, bus, volume_db, pitch)


## Plays any stream once on a bus using the shared player pool (the oldest sound is cut if all players are busy).
func play_stream(stream: AudioStream, bus: String = "SFX", volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = null
	for c in _pool:
		if not c.playing:
			p = c
			break
	if p == null:
		p = _pool[_next_steal]
		_next_steal = (_next_steal + 1) % _pool.size()
	p.stream = stream
	p.bus = bus if AudioServer.get_bus_index(bus) != -1 else "SFX"
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.1, 4.0)
	p.play()
	return p


## Plays a named recipe at a world position (needs a current scene; otherwise parented to this node). Frees itself when done.
func play_sfx_at(sfx_name: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer3D:
	var s := SfxRecipesScript.get_stream(sfx_name)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.bus = "SFX"
	p.volume_db = volume_db
	p.pitch_scale = clampf(pitch, 0.1, 4.0)
	p.unit_size = 6.0
	p.finished.connect(p.queue_free)
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else self
	host.add_child(p)
	p.global_position = pos
	p.play()
	return p


## Plays one voice blip for a typed character of `who`'s line. Punctuation is silent and each speaker only blips on every
## Nth letter (see VoiceProfiles). Called automatically for every Events.speaker_blip.
func blip(who: String, ch: String) -> void:
	if not VoiceProfilesScript.is_voiced(ch):
		return
	if who != _blip_who:
		_blip_who = who
		_blip_counter = 0
	var prof := VoiceProfilesScript.for_speaker(who)
	_blip_counter += 1
	if _blip_counter % int(prof["every"]) != 0:
		return
	var key := "%s|%s|%s" % [prof["base"], prof["wave"], prof["len"]]
	if not _blip_streams.has(key):
		_blip_streams[key] = SynthScript.to_stream(SynthScript.tone(float(prof["base"]), float(prof["len"]), String(prof["wave"]), 1.0, 0.002, 1.5))
	_blip_player.stream = _blip_streams[key]
	_blip_player.volume_db = linear_to_db(float(prof["vol"]))
	_blip_player.pitch_scale = VoiceProfilesScript.pitch_for(prof, ch)
	_blip_player.play()
	if _unreality >= DOUBLE_VOICE_FROM:
		_blip_double.stream = _blip_player.stream
		_blip_double.volume_db = _blip_player.volume_db - 5.0
		_blip_double.pitch_scale = _blip_player.pitch_scale * (0.94 if _unreality < 0.75 else 0.89)
		_blip_double.play()


## Tells the audio layer the hidden Unreality level (done automatically from Events.unreality_changed).
func set_unreality(level: float) -> void:
	_unreality = clampf(level, 0.0, 1.0)


## The Unreality level the audio layer is following.
func unreality() -> float:
	return _unreality


## Seconds between whispers at an Unreality level: INF below WHISPER_FROM, then 70 s falling to 18 s at 1.0.
static func whisper_interval(level: float) -> float:
	if level < WHISPER_FROM:
		return INF
	return lerpf(70.0, 18.0, clampf((level - WHISPER_FROM) / (1.0 - WHISPER_FROM), 0.0, 1.0))


## Plays one whisper right now, very quietly and at a random pitch. Returns the player.
func whisper_now() -> AudioStreamPlayer:
	return play_sfx("whisper", -34.0 + _unreality * 10.0, _whisper_rng.randf_range(0.8, 1.25), "Voice")


func _process(delta: float) -> void:
	if get_tree().paused or _unreality < WHISPER_FROM:
		return
	_whisper_left -= delta
	if _whisper_left <= 0.0:
		whisper_now()
		_whisper_left = whisper_interval(_unreality) * _whisper_rng.randf_range(0.7, 1.3)


## Smoothly lowers Music and Amb by `db` (negative) over `fade` seconds, e.g. while a character speaks.
func duck(db: float = DIALOGUE_DUCK_DB, fade: float = 0.25) -> void:
	_tween_duck(minf(db, 0.0), fade)


## Brings Music and Amb back to full level over `fade` seconds.
func unduck(fade: float = 0.6) -> void:
	_tween_duck(0.0, fade)


## The ducking amount currently being faded to (0 = not ducked).
func duck_target_db() -> float:
	return _duck_db


## Current duck gain actually applied to the Music bus, in dB.
func duck_applied_db() -> float:
	return _duckers[0].volume_db if not _duckers.is_empty() else 0.0


## Muffles (or restores) Music and Amb with a lowpass filter. Used while the game is paused.
func set_muffled(on: bool) -> void:
	for f in _lowpasses:
		f.cutoff_hz = CUTOFF_PAUSED if on else CUTOFF_OPEN


func _tween_duck(db: float, fade: float) -> void:
	_duck_db = db
	if _duck_tween != null:
		_duck_tween.kill()
	_duck_tween = create_tween()
	for d in _duckers:
		_duck_tween.parallel().tween_property(d, "volume_db", db, maxf(fade, 0.01))


func _on_paused(paused: bool) -> void:
	set_muffled(paused)


func _on_unreal_spike(amount: float, _reason: String) -> void:
	if amount >= 0.05 and _rate_ok("spike", 400):
		play_sfx("flea_bite", -8.0, 0.7 + amount * 0.5)


## True (and records the time) if at least `ms` milliseconds passed since the last call with this key.
func _rate_ok(key: String, ms: int) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(key, -100000)) < ms:
		return false
	_last_ms[key] = now
	return true


## Sets a bus's volume from a linear 0..1 value (0 mutes it).
func set_bus_volume(bus: String, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


## Linear 0..1 volume of a bus (1 for an unknown bus).
func get_bus_volume(bus: String) -> float:
	var i := AudioServer.get_bus_index(bus)
	return 1.0 if i == -1 else db_to_linear(AudioServer.get_bus_volume_db(i))


## Switches the room reverb ("none", "room", "hall", "dome", "cave"). Unknown names fall back to "none".
func set_reverb(preset: String) -> void:
	if not REVERB_PRESETS.has(preset):
		preset = "none"
	_reverb_preset = preset
	var cfg: Array = REVERB_PRESETS[preset]
	for r in _reverbs:
		r.wet = cfg[0]
		r.room_size = cfg[1]
		r.damping = cfg[2]


## The current reverb preset name.
func reverb_preset() -> String:
	return _reverb_preset


func _on_dialogue_cue(kind: String, value: Variant) -> void:
	if kind != "sfx":
		return
	if value is Array:
		for v in value:
			play_sfx(str(v))
	else:
		play_sfx(str(value))


func _setup_buses() -> void:
	_reverbs.clear()
	for b in BUS_NAMES:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for b in REVERB_BUSES:
		var idx := AudioServer.get_bus_index(b)
		var r := AudioEffectReverb.new()
		r.dry = 1.0
		r.wet = 0.0
		AudioServer.add_bus_effect(idx, r)
		_reverbs.append(r)
	_duckers.clear()
	_lowpasses.clear()
	for b in ["Music", "Amb"]:
		var idx := AudioServer.get_bus_index(b)
		var amp := AudioEffectAmplify.new()
		AudioServer.add_bus_effect(idx, amp)
		_duckers.append(amp)
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = CUTOFF_OPEN
		AudioServer.add_bus_effect(idx, lp)
		_lowpasses.append(lp)
	set_reverb("none")
