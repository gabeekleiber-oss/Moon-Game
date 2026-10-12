extends Node
## Autoload `Cutscene`: letterbox, fades, waits, hold-Space skip, title cards and camera presets. (F-05)
##
## Write a cutscene as an ordinary coroutine and hand it to play():
##
##     var skipped: bool = await Cutscene.play(func() -> void:
##         await Cutscene.letterbox(true)
##         await Cutscene.fade_in(1.0)
##         await Dialogue.play("moon_01")
##         await Cutscene.wait(0.5)
##         Game.set_flag("moonSpoke")          # end-state: always runs, even when skipped
##         await Cutscene.fade_in(0.5))
##
## Holding Space ~1 s skips: every wait/fade/camera move/dialogue in the sequence FAST-FORWARDS, so the code after
## each `await` still runs and all end-state flags and meters get set. Do not put end-state changes behind
## `if not skipped`. Finish your sequence with the screen visible (call fade_in) unless you mean to stay black.
## While a cutscene runs: HUD hidden, player cannot move/look, InteractionRay is off.

## Emitted once when a skip begins.
signal skipped
signal _wake(serial: int)

## Seconds Space must be held to skip.
const SKIP_HOLD := 1.0
## Height of each letterbox bar as a fraction of the screen (2.39:1 look at 16:9).
const LETTERBOX_FRAC := 0.115
const LAYER_BARS := 15       # above HUD(8)/interaction(10), below the dialogue box(20) so subtitles stay readable
const LAYER_FADE := 50
const LAYER_SKIP := 51
const LAYER_TITLE := 52      # above the black fade so card text shows on black

## Camera presets. `offset` is in the TARGET's local space; targets face -Z (player spawn convention), so the camera
## sits in FRONT of the target (negative Z) looking back at it; pass behind=true to mirror it to the back.
## Presets assume the target's ORIGIN is at floor level (feet); for a prop whose origin is its centre, pass a
## floor-level anchor Node3D instead. `look_height` = metres above the target's origin to aim at; `fov` in degrees; optional `roll` in degrees;
## optional `up_local` replaces the up vector (used by the straight-down "top" shot).
const CAM_PRESETS := {
	"wide": {"offset": Vector3(0.0, 1.8, -6.0), "look_height": 1.2, "fov": 70.0},
	"medium": {"offset": Vector3(0.0, 1.6, -3.2), "look_height": 1.4, "fov": 60.0},
	"close": {"offset": Vector3(0.35, 1.6, -1.4), "look_height": 1.6, "fov": 42.0},
	"low": {"offset": Vector3(0.0, 0.35, -3.0), "look_height": 1.7, "fov": 65.0},
	"high": {"offset": Vector3(0.0, 5.0, -4.0), "look_height": 0.6, "fov": 60.0},
	"top": {"offset": Vector3(0.0, 9.0, 0.0), "look_height": 0.0, "fov": 55.0, "up_local": Vector3(0.0, 0.0, -1.0)},
	"dutch": {"offset": Vector3(0.0, 1.5, -4.0), "look_height": 1.3, "fov": 62.0, "roll": 12.0},
}

var _active: bool = false
var _skippable: bool = true
var _skipping: bool = false
var _id: String = ""
var _hold: float = 0.0
var _serial: int = 0
var _tweens: Array[Tween] = []

var _bars_layer: CanvasLayer
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _bar_amount: float = 0.0
var _fade_layer: CanvasLayer
var _fade: ColorRect
## If true, an act title card plays automatically whenever an act starts (off by default: acts call
## `await Cutscene.act_card(id)` themselves when they want one).
var auto_title_cards: bool = false
var _title_root: Control
## Default target for cam() and for dialogue `cam` cues (set it once per scene: `Cutscene.focus = moon`).
var focus: Node3D = null
var _cam: Camera3D
var _prev_cam: Camera3D
var _cam_active: bool = false
var _title_kicker: Label
var _title_main: Label
var _title_sub: Label
var _skip_root: Control
var _skip_label: Label
var _skip_fill: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_cam = Camera3D.new()
	_cam.name = "CutsceneCamera"
	add_child(_cam)
	Events.dialogue_cue.connect(_on_dialogue_cue)
	Events.dialogue_ended.connect(func(_id: String) -> void:
		if _cam_active and not _active:
			cam_release(0.5))
	Events.act_started.connect(func(id: int) -> void:
		if auto_title_cards:
			act_card(id))


# ---------------------------------------------------------------- public API

## Runs `sequence` (a Callable coroutine) as a cutscene and waits for it. Returns true if the player skipped it,
## false if it ran to the end. Returns false immediately (and does nothing) if another cutscene is running.
func play(sequence: Callable, id: String = "cutscene", skippable: bool = true) -> bool:
	if _active:
		push_warning("Cutscene.play('%s') ignored: '%s' is already running." % [id, _id])
		return false
	begin(id, skippable)
	await sequence.call()
	return await end()


## Low-level start (play() calls this). Locks the player until end().
func begin(id: String = "cutscene", skippable: bool = true) -> void:
	if _active:
		return
	_active = true
	_skippable = skippable
	_skipping = false
	_id = id
	_hold = 0.0
	Events.cutscene_started.emit(id)


## Low-level finish (play() calls this): letterbox out, unlock. Returns whether it was skipped.
func end() -> bool:
	if not _active:
		return false
	if _cam_active:
		await cam_release(0.6)
	if _bar_amount > 0.0:
		await letterbox(false, 0.5)
	var was_skipped := _skipping
	_active = false
	_skipping = false
	_hold = 0.0
	Events.cutscene_ended.emit(_id, was_skipped)
	return was_skipped


## True while a cutscene is running (use to lock input in your own scripts).
func is_active() -> bool:
	return _active


## True while a skip is fast-forwarding the sequence.
func is_skipping() -> bool:
	return _skipping


## Starts a skip as if Space had been held (also useful for tests and debug keys).
func request_skip() -> void:
	if not _active or _skipping:
		return
	_skipping = true
	skipped.emit()
	_wake.emit(-1)
	if Dialogue.is_active():
		Dialogue.stop()
	for tw in _tweens.duplicate():
		if tw.is_valid():
			tw.custom_step(100000.0)


## Waits `seconds` (returns at once when skipping).
func wait(seconds: float) -> void:
	if _skipping or seconds <= 0.0:
		return
	_serial += 1
	var mine := _serial
	get_tree().create_timer(seconds).timeout.connect(func() -> void: _wake.emit(mine))
	while not _skipping:
		var who: int = await _wake
		if who == mine:
			return


## Fades the screen to `color` (default black) over `seconds`.
func fade_out(seconds: float = 0.8, color: Color = Color.BLACK) -> void:
	_fade.color = Color(color.r, color.g, color.b, _fade.color.a)
	await _tween_property(_fade, "color", Color(color.r, color.g, color.b, 1.0), seconds)


## Fades the screen back in (clears the fade colour) over `seconds`.
func fade_in(seconds: float = 0.8) -> void:
	await _tween_property(_fade, "color", Color(_fade.color.r, _fade.color.g, _fade.color.b, 0.0), seconds)


## Slides the cinematic bars in (`on` = true) or out over `seconds`.
func letterbox(on: bool = true, seconds: float = 0.6) -> void:
	var target := 1.0 if on else 0.0
	if _skipping or seconds <= 0.0:
		_set_bars(target)
		return
	var tw := create_tween()
	tw.tween_method(_set_bars, _bar_amount, target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _await_tween(tw)


## Shows a centred title card: `text` big, optional `subtitle` below, optional small `kicker` above. Fades in,
## holds `hold` seconds, fades out. Put a fade_out() before it for a card on black.
func title_card(text: String, subtitle: String = "", hold: float = 2.5, kicker: String = "", fade_time: float = 0.8) -> void:
	_title_kicker.text = kicker
	_title_kicker.visible = kicker != ""
	_title_main.text = text
	_title_sub.text = subtitle
	_title_sub.visible = subtitle != ""
	_title_root.modulate.a = 0.0
	_title_root.visible = true
	await _tween_property(_title_root, "modulate:a", 1.0, fade_time)
	await wait(hold)
	await _tween_property(_title_root, "modulate:a", 0.0, fade_time)
	_title_root.visible = false


## Act title card: fades to black, shows "ACT n" + the act's title, fades back in. Skippable.
## Works standalone (it wraps itself in play() when no cutscene is running); returns true if it was skipped.
func act_card(id: int, hold: float = 2.4) -> bool:
	if not _active:
		return await play(func() -> void: await act_card(id, hold), "act_card_%d" % id)
	await fade_out(0.6)
	await title_card(Acts.title_of(id), "", hold, "ACT %d" % id)
	await fade_in(0.9)
	return _skipping


## Moves the cutscene camera to a preset (CAM_PRESETS) framed on `target` (default: `focus`) over `seconds`.
## The first call takes over from the player's camera; end the shot with cam_release() (play() also does it for you).
func cam(preset: String, target: Node3D = null, seconds: float = 1.0, behind: bool = false) -> void:
	var t: Node3D = target if target != null else focus
	if t == null or not is_instance_valid(t) or not CAM_PRESETS.has(preset):
		push_warning("Cutscene.cam('%s'): needs a valid preset and a target (or Cutscene.focus)." % preset)
		return
	focus = t
	var p: Dictionary = CAM_PRESETS[preset]
	var basis := t.global_transform.basis.orthonormalized()
	var off: Vector3 = p["offset"]
	if behind:
		off.z = -off.z
	var pos := t.global_transform.origin + basis * off
	var aim := t.global_transform.origin + Vector3.UP * float(p["look_height"])
	var up := Vector3.UP
	if p.has("up_local"):
		up = basis * (p["up_local"] as Vector3)
	var dest := Transform3D(Basis.IDENTITY, pos).looking_at(aim, up)
	if p.has("roll"):
		dest.basis = dest.basis * Basis(Vector3(0, 0, 1), deg_to_rad(float(p["roll"])))
	await cam_to(dest, float(p["fov"]), seconds)


## Moves the cutscene camera to an exact world transform and field of view.
func cam_to(dest: Transform3D, fov: float = 60.0, seconds: float = 1.0) -> void:
	_take_camera()
	if _skipping or seconds <= 0.0:
		_cam.global_transform = dest
		_cam.fov = fov
		return
	var from := _cam.global_transform
	var from_fov := _cam.fov
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		_cam.global_transform = from.interpolate_with(dest, k)
		_cam.fov = lerpf(from_fov, fov, k), 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _await_tween(tw)


## Hands the view back to the player's camera (eased over `seconds`).
func cam_release(seconds: float = 0.8) -> void:
	if not _cam_active:
		return
	if _prev_cam != null and is_instance_valid(_prev_cam):
		await cam_to(_prev_cam.global_transform, _prev_cam.fov, seconds)
		if is_instance_valid(_prev_cam):
			_prev_cam.make_current()
	_cam_active = false


## Short camera shake on whatever camera is current. Does nothing under Reduced Motion (or while skipping).
func shake(amount: float = 0.05, seconds: float = 0.4) -> void:
	if _skipping or bool(Game.settings.get("reduced_motion", false)):
		return
	var c := get_viewport().get_camera_3d()
	if c == null:
		return
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		var a := amount * (1.0 - k)
		c.h_offset = randf_range(-a, a)
		c.v_offset = randf_range(-a, a), 0.0, 1.0, seconds)
	await _await_tween(tw)
	if is_instance_valid(c):
		c.h_offset = 0.0
		c.v_offset = 0.0


## Current fade opacity 0..1 (for scripts/tests).
func fade_alpha() -> float:
	return _fade.color.a


## Current letterbox amount 0..1.
func letterbox_amount() -> float:
	return _bar_amount


# ---------------------------------------------------------------- internals

func _tween_property(obj: Object, prop: String, to: Variant, seconds: float) -> void:
	if _skipping or seconds <= 0.0:
		obj.set_indexed(NodePath(prop), to)
		return
	var tw := create_tween()
	tw.tween_property(obj, prop, to, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _await_tween(tw)


func _await_tween(tw: Tween) -> void:
	_tweens.append(tw)
	await tw.finished
	_tweens.erase(tw)


func _take_camera() -> void:
	if _cam_active:
		return
	var cur := get_viewport().get_camera_3d()
	if cur != null and cur != _cam:
		_prev_cam = cur
		_cam.global_transform = cur.global_transform
		_cam.fov = cur.fov
	_cam.make_current()
	_cam_active = true


## Dialogue nodes may carry `"cam": "close"` (a preset on Cutscene.focus) or `"cam": "release"`.
func _on_dialogue_cue(kind: String, value: Variant) -> void:
	if kind != "cam":
		return
	if str(value) == "release":
		cam_release(0.8)
	else:
		cam(str(value), null, 1.0)


func _set_bars(amount: float) -> void:
	_bar_amount = amount
	_bar_top.anchor_bottom = LETTERBOX_FRAC * amount
	_bar_top.offset_bottom = 0.0
	_bar_bottom.anchor_top = 1.0 - LETTERBOX_FRAC * amount
	_bar_bottom.offset_top = 0.0


func _process(delta: float) -> void:
	var show_prompt := _active and _skippable and not _skipping
	_skip_root.visible = show_prompt
	if not show_prompt:
		_hold = 0.0
		return
	if Input.is_action_pressed("jump"):
		_hold += delta
	else:
		_hold = maxf(0.0, _hold - delta * 2.0)
	_skip_fill.anchor_right = clampf(_hold / SKIP_HOLD, 0.0, 1.0)
	_skip_label.modulate.a = 0.55 + 0.45 * clampf(_hold / SKIP_HOLD, 0.0, 1.0)
	if _hold >= SKIP_HOLD:
		request_skip()


func _build_ui() -> void:
	_bars_layer = CanvasLayer.new()
	_bars_layer.layer = LAYER_BARS
	add_child(_bars_layer)
	_bar_top = _make_bar()
	_bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_bottom = _make_bar()
	_bar_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bars_layer.add_child(_bar_top)
	_bars_layer.add_child(_bar_bottom)
	_set_bars(0.0)

	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = LAYER_FADE
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 0)
	_fade_layer.add_child(_fade)

	var title_layer := CanvasLayer.new()
	title_layer.layer = LAYER_TITLE
	add_child(title_layer)
	_title_root = Control.new()
	_title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_root.visible = false
	title_layer.add_child(_title_root)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -520.0
	col.offset_right = 520.0
	col.offset_top = -110.0
	col.offset_bottom = 110.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	_title_root.add_child(col)
	_title_kicker = _make_title_label(22, Color(1.0, 0.86, 0.42))
	_title_main = _make_title_label(56, Color(1.0, 0.97, 0.9))
	_title_sub = _make_title_label(26, Color(0.9, 0.85, 0.8))
	col.add_child(_title_kicker)
	col.add_child(_title_main)
	col.add_child(_title_sub)

	var skip_layer := CanvasLayer.new()
	skip_layer.layer = LAYER_SKIP
	add_child(skip_layer)
	_skip_root = Control.new()
	_skip_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_root.visible = false
	skip_layer.add_child(_skip_root)
	_skip_label = Label.new()
	_skip_label.text = "Hold SPACE to skip"
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.offset_left = -260.0
	_skip_label.offset_top = -64.0
	_skip_label.offset_right = -24.0
	_skip_label.offset_bottom = -34.0
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_label.add_theme_font_size_override("font_size", 18)
	_skip_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_skip_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08, 0.9))
	_skip_label.add_theme_constant_override("outline_size", 5)
	_skip_root.add_child(_skip_label)
	var track := ColorRect.new()
	track.color = Color(1, 1, 1, 0.18)
	track.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	track.offset_left = -260.0
	track.offset_top = -30.0
	track.offset_right = -24.0
	track.offset_bottom = -26.0
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_root.add_child(track)
	_skip_fill = ColorRect.new()
	_skip_fill.color = Color(1.0, 0.86, 0.42, 0.95)
	_skip_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_skip_fill.anchor_right = 0.0
	_skip_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_skip_fill)


func _make_bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _make_title_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
