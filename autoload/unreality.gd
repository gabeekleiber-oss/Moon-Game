extends Node
## Autoload `Unreality`: the hidden insanity value (0..1) that the whole game reads. The player never sees a number.
## It rises slowly while you play, jumps at story beats, and every system reflects it: grade, lens, audio, geometry, characters.
## (Maths lives in UnrealityModel so it is testable; this node steps it each frame and announces changes on Events.)
##
## WRITING WORLD CODE AGAINST IT (the pattern every agent should use):
##     var k := Unreality.ramp(0.3, 0.7)              # 0 below 0.3, 1 above 0.7, smooth between; scale any effect by k
##     if Unreality.wrongs("frame_pope_03"):          # deterministic: this object starts being wrong at its own threshold
##         frame.rotation.z = 0.04                    #   (so wrongness accumulates in a stable, repeatable order)
##     Unreality.listen(func(level): ...)             # or connect Events.unreality_changed
## Story code: Unreality.raise(0.05, "mary sue's face") (permanent) / Unreality.spike(0.2, "the finger") (decays)
##             Unreality.set_floor(0.3) at the start of an act (the act's minimum).
## SHADERS: every ShaderMaterial can read the level directly: `global uniform float unreality;` (0..1) and `global uniform float unreal_time;`
## (slow time, frozen under Reduced Motion). Use them for surface decay, texture swim, veins, sweat: see docs/ART_BIBLE.md "Materials".
## Reduced Motion: effects that MOVE (sway, wobble, breathing) must multiply by `motion_scale()`; colour/audio effects need not.

var model := UnrealityModel.new()
var _last_emitted: float = 0.0
var _last_band: int = 0
var _time: float = 0.0
var frozen: bool = false           ## true during menus/debug if you want the drift to stop

## Smoothed felt value 0..1.
var level: float:
	get: return model.level


func _process(delta: float) -> void:
	_time += delta
	RenderingServer.global_shader_parameter_set("unreal_time", 0.0 if motion_scale() == 0.0 else _time)
	if frozen or get_tree().paused:
		return
	model.step(delta)
	_announce("")


## Smoothstep remap of the current level (see header).
func ramp(a: float, b: float) -> float:
	return UnrealityModel.ramp_of(model.level, a, b)


## Current band index 0..5 (0 ordinary, 1 off, 2 wrong, 3 fraying, 4 unmoored, 5 ruin).
func band() -> int:
	return UnrealityModel.band_of(model.level)


func band_name() -> String:
	return UnrealityModel.BAND_NAMES[band()]


## True once the level passed this object's personal threshold. `bias` shifts it (negative = goes wrong earlier).
## Thresholds are spread over 0.1..0.9 so things go wrong one by one in the same order every playthrough.
func wrongs(id: String, bias: float = 0.0) -> bool:
	return model.level >= 0.1 + UnrealityModel.hash01(id) * 0.8 + bias


## 1.0 normally, 0.0 when Reduced Motion is on. Multiply every MOVING effect by this.
func motion_scale() -> float:
	return 0.0 if bool(Game.settings.get("reduced_motion", false)) else 1.0


## Permanent rise (story beats).
func raise(amount: float, reason: String = "") -> void:
	model.raise(amount)
	_announce(reason)


## Raise to at least `value` (permanent).
func raise_to(value: float, reason: String = "") -> void:
	model.raise_to(value)
	_announce(reason)


## Temporary jolt that decays (shocks).
func spike(amount: float, reason: String = "") -> void:
	model.jolt(amount)
	Events.unreality_spiked.emit(amount, reason)
	_announce(reason)


## Sets the minimum the current act allows (base is lifted to it).
func set_floor(value: float) -> void:
	model.floor_ = clampf(value, 0.0, 1.0)
	model.raise_to(model.floor_)


## Debug / cutscene: set the value outright (can lower). `instant` skips the easing.
func force(value: float, instant: bool = true) -> void:
	model.force(value, instant)
	model.floor_ = minf(model.floor_, model.base)
	_announce("force")


## Calls `fn(level)` whenever the level changes noticeably.
func listen(fn: Callable) -> void:
	Events.unreality_changed.connect(func(l: float, _d: float, _r: String) -> void: fn.call(l))


func _announce(reason: String) -> void:
	var l := model.level
	RenderingServer.global_shader_parameter_set("unreality", l)
	if absf(l - _last_emitted) >= 0.002 or reason != "":
		Events.unreality_changed.emit(l, l - _last_emitted, reason)
		_last_emitted = l
	var b := UnrealityModel.band_of(l)
	if b != _last_band:
		_last_band = b
		Events.unreality_band_changed.emit(b, UnrealityModel.BAND_NAMES[b])
