class_name KickMeter
extends CanvasLayer
## Timing bar for the boot-kick (C-01): a marker sweeps across a bar, press E (or click) while it is inside the green zone.
##
## Usage: `var m := KickMeter.new(); add_child(m); m.start(1.4, 0.62, 0.11); var hit: bool = await m.resolved`.
## Missing the zone, or letting the sweep run out, resolves `false`. The chapter funnels every outcome to the same canon kick.
## `press()` is the same as pressing E (tests call it). Under Reduced Motion the zone is widened (assist).

## Emitted once per start(): true if the press landed inside the zone.
signal resolved(hit: bool)

var _root: Control
var _bar: ColorRect
var _zone: ColorRect
var _marker: ColorRect
var _label: Label
var _active: bool = false
var _t: float = 0.0
var _duration: float = 1.4
var _center: float = 0.62
var _half: float = 0.11
const BAR_W := 420.0


func _init() -> void:
	layer = 35
	visible = false


func _ready() -> void:
	_build()


## True while the meter is waiting for a press.
func is_active() -> bool:
	return _active


## Marker position 0..1 along the bar.
func marker_position() -> float:
	return clampf(_t / _duration, 0.0, 1.0)


## True if the marker is inside the zone right now.
func in_zone() -> bool:
	return absf(marker_position() - _center) <= _half


## Starts one sweep. `duration` seconds left to right; the zone is `center` +/- `half` (0..1 of the bar).
func start(duration: float = 1.4, center: float = 0.62, half: float = 0.11) -> void:
	if _marker == null:
		_build()
	_duration = maxf(0.2, duration)
	_center = center
	_half = half * (1.6 if bool(Game.settings.get("assist", false)) else 1.0)
	_t = 0.0
	_active = true
	visible = true
	_label.text = "[E] KICK!"
	_zone.position.x = (_center - _half) * BAR_W
	_zone.size.x = _half * 2.0 * BAR_W
	_update_marker()


## Press now (what E / click do). Resolves hit or miss.
func press() -> void:
	if not _active:
		return
	_finish(in_zone())


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_update_marker()
	if _t >= _duration:
		_finish(false)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = event.is_action("interact")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if pressed:
		get_viewport().set_input_as_handled()
		press()


func _finish(hit: bool) -> void:
	_active = false
	_label.text = "THWACK!" if hit else "..."
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func() -> void: visible = false)
	resolved.emit(hit)


func _update_marker() -> void:
	_marker.position.x = marker_position() * BAR_W - _marker.size.x * 0.5


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_root.position = Vector2(-BAR_W * 0.5, -140)
	_root.size = Vector2(BAR_W, 60)
	add_child(_root)
	_label = Label.new()
	_label.text = "[E] KICK!"
	_label.position = Vector2(0, -34)
	_label.size = Vector2(BAR_W, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1, 0.93, 0.7))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 6)
	_root.add_child(_label)
	_bar = ColorRect.new()
	_bar.color = Color(0.05, 0.06, 0.1, 0.85)
	_bar.size = Vector2(BAR_W, 26)
	_root.add_child(_bar)
	_zone = ColorRect.new()
	_zone.color = Color(0.45, 0.85, 0.5, 0.9)
	_zone.size = Vector2(80, 26)
	_root.add_child(_zone)
	_marker = ColorRect.new()
	_marker.color = Color(1, 0.95, 0.8)
	_marker.size = Vector2(6, 38)
	_marker.position.y = -6
	_root.add_child(_marker)
