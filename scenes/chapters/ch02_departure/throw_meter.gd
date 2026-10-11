class_name ThrowMeter
extends CanvasLayer
## Hold-to-charge power meter for the Ch2 throws (C-02). Hold E (or the left mouse button) to charge, release to throw.
##
## Power sweeps 0 -> 1 -> 0 while held. `set_zone(center, half)` paints the green "ideal" zone (center < 0 hides it).
## `begin_charge()` / `release()` are what the input does, so tests can call them. `released(power)` fires once per throw.

## Emitted when the player lets go: the power (0..1) at that moment.
signal released(power: float)

const BAR_W := 420.0
const SWEEP_PER_SEC := 0.8

var _root: Control
var _zone: ColorRect
var _fill: ColorRect
var _label: Label
var _armed: bool = false
var _charging: bool = false
var _t: float = 0.0
var _power: float = 0.0


func _init() -> void:
	layer = 35
	visible = false


func _ready() -> void:
	_build()


func is_armed() -> bool:
	return _armed


func is_charging() -> bool:
	return _charging


## Current charge 0..1.
func power() -> float:
	return _power


## Shows the meter and waits for a charge. `text` is the prompt above the bar.
func arm(text: String) -> void:
	if _root == null:
		_build()
	_armed = true
	_charging = false
	_power = 0.0
	_t = 0.0
	_label.text = text
	_fill.size.x = 0.0
	visible = true


func disarm() -> void:
	_armed = false
	_charging = false
	visible = false


## Paints the ideal zone; center < 0 hides it.
func set_zone(center: float, half: float) -> void:
	if _zone == null:
		return
	_zone.visible = center >= 0.0
	_zone.position.x = (center - half) * BAR_W
	_zone.size.x = half * 2.0 * BAR_W


func zone_visible() -> bool:
	return _zone != null and _zone.visible


func begin_charge() -> void:
	if not _armed or _charging:
		return
	_charging = true
	_t = 0.0


## Lets go: emits `released` with the current power and disarms.
func release() -> void:
	if not _armed or not _charging:
		return
	var p := _power
	disarm()
	released.emit(p)


## Test helper: throws at exactly this power (what a perfectly timed release would do).
func release_at(p: float) -> void:
	if not _armed:
		return
	disarm()
	released.emit(clampf(p, 0.0, 1.0))


func _process(delta: float) -> void:
	if not _charging:
		return
	_t += delta
	_power = pingpong(_t * SWEEP_PER_SEC, 1.0)
	_fill.size.x = _power * BAR_W


func _input(event: InputEvent) -> void:
	if not _armed:
		return
	if event is InputEventKey and event.is_action("interact") and not event.echo:
		get_viewport().set_input_as_handled()
		if event.pressed:
			begin_charge()
		else:
			release()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if event.pressed:
			begin_charge()
		else:
			release()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_root.position = Vector2(-BAR_W * 0.5, -130)
	_root.size = Vector2(BAR_W, 40)
	add_child(_root)
	_label = Label.new()
	_label.position = Vector2(-80, -36)
	_label.size = Vector2(BAR_W + 160, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	_root.add_child(_label)
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.06, 0.1, 0.85)
	bar.size = Vector2(BAR_W, 26)
	_root.add_child(bar)
	_zone = ColorRect.new()
	_zone.color = Color(0.45, 0.85, 0.5, 0.75)
	_zone.size = Vector2(60, 26)
	_zone.visible = false
	_root.add_child(_zone)
	_fill = ColorRect.new()
	_fill.color = Color(1.0, 0.82, 0.4, 0.9)
	_fill.size = Vector2(0, 8)
	_fill.position = Vector2(0, 9)
	_root.add_child(_fill)
