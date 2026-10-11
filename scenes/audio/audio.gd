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
## Sound names come from SfxRecipes.NAMES. Works while the tree is paused (PROCESS_MODE_ALWAYS).

const BUS_NAMES: Array[String] = ["Music", "SFX", "Amb", "Voice"]
const REVERB_BUSES: Array[String] = ["SFX", "Amb", "Voice"]
const POOL_SIZE := 12
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


## Plays a named recipe once, non-positionally. Returns the player (null for an unknown name).
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0, bus: String = "SFX") -> AudioStreamPlayer:
	var s := SfxRecipes.get_stream(sfx_name)
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
	var s := SfxRecipes.get_stream(sfx_name)
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
	set_reverb("none")
