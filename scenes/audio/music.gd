extends Node
## Autoload `Music`: plays the game's procedural music (the Moon Waltz in a different costume for each chapter). (F-09)
##
## API:
##   Music.play_chapter(5)            start chapter 5's treatment (0 = title screen); crossfades from whatever is playing
##   Music.play("lake", 1.5)          start a named MusicScore variation, fading in over 1.5 s
##   Music.stop(1.0)                  fade out and stop
##   Music.set_intensity(0.8)         0..1: faster tempo, plus an octave double and detune from 0.5 (driven by Flea automatically)
##   Music.silence(10.0)              hold the music back for 10 more seconds
##   Music.current() / is_playing() / state()   what is playing ("" if nothing); state is idle | fading_out | warming | playing
## Automatic (turn off with the flags): `auto_chapter` starts the matching music on Events.chapter_started and warms up the next
## chapter in the background; `flea_drives_intensity` maps Flea 50..90 to intensity 0..1.
## Notes are pre-rendered on a worker thread (one note costs ~50 ms to synthesise), so starting a variation first shows state
## "warming" for a couple of seconds, then fades in. A note that is somehow not ready yet is skipped, never rendered on the main
## thread. Plays on the "Music" bus, so Audio's dialogue ducking and pause muffling apply automatically.

const VOICES := 28
const SILENT_DB := -60.0

## Start the chapter's music on Events.chapter_started (and pre-render the next chapter's).
var auto_chapter: bool = true
## Let the Flea Meter push the music's intensity.
var flea_drives_intensity: bool = true

var _state: String = "idle"
var _name: String = ""
var _variation: Dictionary = {}
var _seq: MusicSequencer
var _intensity: float = 0.0
var _fade_in: float = 1.0
var _players: Array[AudioStreamPlayer] = []
var _next_steal: int = 0
var _fader: AudioEffectAmplify
var _fade_tween: Tween
var _requested: Dictionary = {}   # note keys already handed to a worker
var _pending_keys: Array = []
var _queued_play: Dictionary = {}


func _init() -> void:
	name = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus == -1:
		bus = 0   # Audio autoload creates the bus; fall back to Master so nothing crashes
	_fader = AudioEffectAmplify.new()
	_fader.volume_db = SILENT_DB
	AudioServer.add_bus_effect(bus, _fader)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
		add_child(p)
		_players.append(p)
	Events.chapter_started.connect(_on_chapter_started)
	Events.flea_changed.connect(_on_flea)


## Starts a named variation (see MusicScore.VARIATIONS), crossfading from the current music. Same name again does nothing.
func play(variation_name: String, fade_in: float = 1.0) -> void:
	if not MusicScore.VARIATIONS.has(variation_name):
		push_warning("Music: unknown variation '%s'" % variation_name)
		return
	if variation_name == _name and _state != "idle":
		return
	_name = variation_name
	_fade_in = maxf(fade_in, 0.01)
	_queued_play = MusicScore.variation(variation_name)
	if _state == "playing":
		_state = "fading_out"
		_tween_fader(SILENT_DB, 0.8, _start_queued)
	elif _state == "fading_out":
		pass   # already fading; _start_queued will pick up the newest request
	else:
		_start_queued()


## Starts the music for a chapter (0 = title screen).
func play_chapter(chapter_id: int, fade_in: float = 1.0) -> void:
	play(String(MusicScore.CHAPTER_VARIATION.get(chapter_id, "")), fade_in)


## Fades out and stops. Notes already sounding ring out naturally.
func stop(fade_out: float = 1.0) -> void:
	_name = ""
	_queued_play = {}
	if _state == "idle":
		return
	_state = "fading_out"
	_tween_fader(SILENT_DB, maxf(fade_out, 0.01), func() -> void:
		if _state == "fading_out" and _queued_play.is_empty():
			_state = "idle"
			_seq = null)


## Sets the intensity (0..1). Crossing 0.5 pre-renders the extra layer in the background.
func set_intensity(v: float) -> void:
	var old := _intensity
	_intensity = clampf(v, 0.0, 1.0)
	if _seq != null:
		_seq.set_intensity(_intensity)
		if (old >= MusicSequencer.DOUBLE_AT) != (_intensity >= MusicSequencer.DOUBLE_AT):
			_request(_keys_for(_variation, _intensity))


## The current intensity.
func intensity() -> float:
	return _intensity


## Holds the music back for `seconds` more.
func silence(seconds: float) -> void:
	if _seq != null:
		_seq.silence(seconds)


## Name of the variation that is playing or about to play ("" when stopped).
func current() -> String:
	return _name


## idle | fading_out | warming | playing
func state() -> String:
	return _state


## True once music has started (not while still warming up or idle).
func is_playing() -> bool:
	return _state == "playing"


## Starts rendering a variation's notes in the background so a later play() starts instantly.
func prewarm(variation_name: String) -> void:
	if MusicScore.VARIATIONS.has(variation_name):
		_request(_keys_for(MusicScore.variation(variation_name), 0.0))


func _process(delta: float) -> void:
	match _state:
		"warming":
			if _all_cached(_pending_keys):
				_begin_playing()
		"playing":
			for ev in _seq.advance(delta):
				_play_event(ev)


func _start_queued() -> void:
	if _queued_play.is_empty():
		_state = "idle"
		return
	_variation = _queued_play
	_queued_play = {}
	_pending_keys = _keys_for(_variation, _intensity)
	_request(_pending_keys)
	_state = "warming"


func _begin_playing() -> void:
	_seq = MusicSequencer.new(_variation)
	_seq.set_intensity(_intensity)
	_state = "playing"
	_fader.volume_db = SILENT_DB
	_tween_fader(0.0, _fade_in, Callable())


func _play_event(ev: Dictionary) -> void:
	var inst: String = ev["inst"]
	var midi: int = ev["midi"]
	var dur: float = ev["dur"]
	var cents: float = ev["detune"]
	if not Instruments.is_cached(inst, midi, dur, cents):
		_request([[inst, midi, dur, cents]])   # never render on the main thread: skip this note, it will be ready next loop
		return
	var p: AudioStreamPlayer = null
	for c in _players:
		if not c.playing:
			p = c
			break
	if p == null:
		p = _players[_next_steal]
		_next_steal = (_next_steal + 1) % _players.size()
	p.stream = Instruments.stream(inst, midi, dur, cents)
	p.volume_db = float(ev["vol_db"]) + float(_variation["vol_db"])
	p.play()


func _tween_fader(db: float, secs: float, done: Callable) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fader, "volume_db", db, secs)
	if done.is_valid():
		_fade_tween.tween_callback(done)


## Note keys ([inst, midi, dur, cents]) for one full loop of a variation at an intensity.
func _keys_for(v: Dictionary, at_intensity: float) -> Array:
	var seen := {}
	var out: Array = []
	for e in MusicSequencer.new(v).loop_events(at_intensity):
		var k := [e["inst"], e["midi"], e["dur"], e["detune"]]
		var id := "%s|%d|%.2f|%d" % [k[0], k[1], k[2], int(round(k[3]))]
		if not seen.has(id):
			seen[id] = true
			out.append(k)
	return out


func _all_cached(keys: Array) -> bool:
	for k in keys:
		if not Instruments.is_cached(k[0], k[1], k[2], k[3]):
			return false
	return true


## Hands uncached, not-yet-requested notes to one worker-thread task.
func _request(keys: Array) -> void:
	var todo: Array = []
	for k in keys:
		var id := "%s|%d|%.2f|%d" % [k[0], k[1], k[2], int(round(k[3]))]
		if _requested.has(id) or Instruments.is_cached(k[0], k[1], k[2], k[3]):
			continue
		_requested[id] = true
		todo.append(k)
	if not todo.is_empty():
		WorkerThreadPool.add_task(_render_batch.bind(todo), false, "music pre-render")


func _render_batch(keys: Array) -> void:
	for k in keys:
		Instruments.stream(k[0], k[1], k[2], k[3])


func _on_chapter_started(id: int) -> void:
	if not auto_chapter:
		return
	play_chapter(id)
	var next_name := String(MusicScore.CHAPTER_VARIATION.get(id + 1, ""))
	if next_name != "" and next_name != _name:
		prewarm(next_name)


func _on_flea(value: float, _delta: float, _reason: String) -> void:
	if flea_drives_intensity:
		set_intensity((value - 50.0) / 40.0)
