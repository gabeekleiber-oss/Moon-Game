extends Node
## Autoload `Music`: plays the game's procedural music (the Moon Waltz in a different costume for each act). (F-09)
##
## API:
##   Music.play_act(5)                start act 5's treatment (0 = title screen); crossfades from whatever is playing
##   Music.play("lake", 1.5)          start a named MusicScore variation, fading in over 1.5 s
##   Music.stop(1.0)                  fade out and stop
##   Music.set_unreality(0.6)         0..1: the music detunes in four steps (automatic from Events.unreality_changed)
##   Music.set_intensity(0.8)         0..1: faster tempo, plus an octave double and detune from 0.5 (manual; Unreality drives detune separately)
##   Music.silence(10.0)              hold the music back for 10 more seconds
##   Music.current() / is_playing() / state()   what is playing ("" if nothing); state is idle | fading_out | warming | playing
## Automatic (turn off with the flag): `auto_act` starts the matching music on Events.act_started and warms up the next act's
## notes in the background.
## Notes are pre-rendered on a worker thread (one note costs ~50 ms to synthesise), so starting a variation first shows state
## "warming" for a couple of seconds, then fades in. A note that is somehow not ready yet is skipped, never rendered on the main
## thread. Plays on the "Music" bus, so Audio's dialogue ducking and pause muffling apply automatically.

const MusicScoreScript = preload("res://scenes/audio/music_score.gd")
const MusicSequencerScript = preload("res://scenes/audio/music_sequencer.gd")
const InstrumentsScript = preload("res://scenes/audio/instruments.gd")
const VOICES := 28
const SILENT_DB := -60.0

## Start the act's music on Events.act_started (and pre-render the next act's).
var auto_act: bool = true
## Let the hidden Unreality level detune the music (Events.unreality_changed -> set_unreality).
var unreality_drives_detune: bool = true

var _state: String = "idle"
var _name: String = ""
var _variation: Dictionary = {}
var _seq: RefCounted
var _intensity: float = 0.0
var _unreality: float = 0.0
var _fade_in: float = 1.0
var _players: Array[AudioStreamPlayer] = []
var _next_steal: int = 0
var _fader: AudioEffectAmplify
var _fade_tween: Tween
var _requested: Dictionary = {}   # note keys already handed to a worker
var _pending_keys: Array = []
var _queued_play: Dictionary = {}
var _tasks: Array[int] = []        # worker-thread task ids still to be collected
var _quitting: bool = false        # set on exit so workers stop after their current note


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
	Events.act_started.connect(_on_act_started)
	Events.unreality_changed.connect(_on_unreality)


## Starts a named variation (see MusicScoreScript.VARIATIONS), crossfading from the current music. Same name again does nothing.
func play(variation_name: String, fade_in: float = 1.0) -> void:
	if not MusicScoreScript.VARIATIONS.has(variation_name):
		push_warning("Music: unknown variation '%s'" % variation_name)
		return
	if variation_name == _name and _state != "idle":
		return
	_name = variation_name
	_fade_in = maxf(fade_in, 0.01)
	_queued_play = MusicScoreScript.variation(variation_name)
	if _state == "playing":
		_state = "fading_out"
		_tween_fader(SILENT_DB, 0.8, _start_queued)
	elif _state == "fading_out":
		pass   # already fading; _start_queued will pick up the newest request
	else:
		_start_queued()


## Starts the music for an act (0 = title screen).
func play_act(act_id: int, fade_in: float = 1.0) -> void:
	play(String(MusicScoreScript.ACT_VARIATION.get(act_id, "")), fade_in)


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
		if (old >= MusicSequencerScript.DOUBLE_AT) != (_intensity >= MusicSequencerScript.DOUBLE_AT):
			_request(_keys_for(_variation, _intensity, _unreality))


## The current intensity.
func intensity() -> float:
	return _intensity


## Sets the Unreality level (0..1). When it enters a new detune band, that band's notes (and the next band's) are pre-rendered
## in the background so the change is never a hitch.
func set_unreality(level: float) -> void:
	var old_band := MusicSequencerScript.band_for(_unreality)
	_unreality = clampf(level, 0.0, 1.0)
	if _seq != null:
		_seq.set_unreality(_unreality)
	if not _variation.is_empty() and MusicSequencerScript.band_for(_unreality) != old_band:
		_request(_keys_for(_variation, _intensity, _unreality))
		_request(_keys_for(_variation, _intensity, minf(_unreality + 0.25, 1.0)))


## The Unreality level the music is following.
func unreality() -> float:
	return _unreality


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
	if MusicScoreScript.VARIATIONS.has(variation_name):
		_request(_keys_for(MusicScoreScript.variation(variation_name), 0.0, _unreality))


## On exit, tell workers to stop after the note they are rendering and wait for them: otherwise the engine tears down the shared
## note cache under a running thread and crashes at shutdown.
func _exit_tree() -> void:
	_quitting = true
	for id in _tasks:
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()


func _process(delta: float) -> void:
	_collect_finished_tasks()
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
	_pending_keys = _keys_for(_variation, _intensity, _unreality)
	_request(_pending_keys)
	_state = "warming"


func _begin_playing() -> void:
	_seq = MusicSequencerScript.new(_variation)
	_seq.set_intensity(_intensity)
	_seq.set_unreality(_unreality)
	_state = "playing"
	_fader.volume_db = SILENT_DB
	_tween_fader(0.0, _fade_in, Callable())


func _play_event(ev: Dictionary) -> void:
	var inst: String = ev["inst"]
	var midi: int = ev["midi"]
	var dur: float = ev["dur"]
	var cents: float = ev["detune"]
	if not InstrumentsScript.is_cached(inst, midi, dur, cents):
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
	p.stream = InstrumentsScript.stream(inst, midi, dur, cents)
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
func _keys_for(v: Dictionary, at_intensity: float, at_unreality: float = 0.0) -> Array:
	var seen := {}
	var out: Array = []
	for e in MusicSequencerScript.new(v).loop_events(at_intensity, at_unreality):
		var k := [e["inst"], e["midi"], e["dur"], e["detune"]]
		var id := "%s|%d|%.2f|%d" % [k[0], k[1], k[2], int(round(k[3]))]
		if not seen.has(id):
			seen[id] = true
			out.append(k)
	return out


func _all_cached(keys: Array) -> bool:
	for k in keys:
		if not InstrumentsScript.is_cached(k[0], k[1], k[2], k[3]):
			return false
	return true


## Hands uncached, not-yet-requested notes to one worker-thread task.
func _request(keys: Array) -> void:
	var todo: Array = []
	for k in keys:
		var id := "%s|%d|%.2f|%d" % [k[0], k[1], k[2], int(round(k[3]))]
		if _requested.has(id) or InstrumentsScript.is_cached(k[0], k[1], k[2], k[3]):
			continue
		_requested[id] = true
		todo.append(k)
	if not todo.is_empty():
		_tasks.append(WorkerThreadPool.add_task(_render_batch.bind(todo), false, "music pre-render"))


func _render_batch(keys: Array) -> void:
	for k in keys:
		if _quitting:
			return
		InstrumentsScript.stream(k[0], k[1], k[2], k[3])


func _on_act_started(id: int) -> void:
	if not auto_act:
		return
	play_act(id)
	var next_name := String(MusicScoreScript.ACT_VARIATION.get(id + 1, ""))
	if next_name != "" and next_name != _name:
		prewarm(next_name)


func _on_unreality(level: float, _delta: float, _reason: String) -> void:
	if unreality_drives_detune:
		set_unreality(level)


func _collect_finished_tasks() -> void:
	var i := _tasks.size() - 1
	while i >= 0:
		if WorkerThreadPool.is_task_completed(_tasks[i]):
			WorkerThreadPool.wait_for_task_completion(_tasks[i])
			_tasks.remove_at(i)
		i -= 1
