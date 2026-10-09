class_name DialogueBox
extends CanvasLayer
## On-screen dialogue presenter: speaker tag, typewriter text, numbered choices. (F-01)
##
## Driven by the Dialogue autoload (or any script): call `show_line(node)` with a runner node dictionary,
## listen to `advance_requested` (line finished, player wants the next one) and `choice_selected(index)`.
## Input: E / Space / Enter / click skips the typewriter, then advances; keys 1-4 (or click) pick a choice.
## Emits Events.speaker_blip(who, ch) for every newly visible non-space character (audio hooks into that).

## Player wants the next line (current line is fully shown and has no choices).
signal advance_requested
## Player picked choice `index` (0-based).
signal choice_selected(index: int)

## Ignore input this long after a line starts, so the [E] that opened the dialogue cannot also skip it.
const INPUT_GUARD := 0.2

var _who: String = ""
var _times := PackedFloat32Array()
var _elapsed: float = 0.0
var _shown: int = 0
var _typing: bool = false
var _choices: Array = []
var _serial: int = 0
var _guard: float = 0.0

var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _hint: Label
var _choice_box: VBoxContainer


func _init() -> void:
	layer = 20
	name = "DialogueBox"
	visible = false


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 80.0
	_panel.offset_right = -80.0
	_panel.offset_top = -190.0
	_panel.offset_bottom = -28.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.12, 0.88)
	style.border_color = Color(1.0, 0.86, 0.42, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	root.add_child(_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 20)
	_speaker.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	col.add_child(_speaker)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 24)
	_text.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	col.add_child(_text)

	_choice_box = VBoxContainer.new()
	col.add_child(_choice_box)

	_hint = Label.new()
	_hint.text = "▼"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color(1, 0.86, 0.42, 0.8))
	_hint.visible = false
	col.add_child(_hint)


## Presents a runner node ({who, text, choices, wait, ...}). Honours `wait` (pause before the line appears).
func show_line(node: Dictionary) -> void:
	_serial += 1
	var my_serial := _serial
	visible = true
	_clear_choices()
	_hint.visible = false
	_typing = false
	_who = str(node.get("who", ""))
	_speaker.text = _display_name(_who)
	_speaker.visible = _who != ""
	_text.text = str(node.get("text", ""))
	_text.visible_characters = 0
	_choices = node.get("choices", []) as Array
	_guard = INPUT_GUARD
	var wait := float(node.get("wait", 0.0))
	if wait > 0.0:
		_text.visible_characters = 0
		await get_tree().create_timer(wait).timeout
		if my_serial != _serial:
			return
	_times = Typewriter.reveal_times(_text.text)
	_elapsed = 0.0
	_shown = 0
	_typing = true


## Hides the box and cancels any pending line.
func hide_box() -> void:
	_serial += 1
	_typing = false
	_clear_choices()
	visible = false


## True while characters are still being revealed.
func is_typing() -> bool:
	return _typing


## Shows the whole line immediately (also emits blips for nothing: skipped text is silent).
func skip_typing() -> void:
	if not _typing:
		return
	_text.visible_characters = -1
	_shown = _text.text.length()
	_finish_typing()


func _process(delta: float) -> void:
	_guard = maxf(0.0, _guard - delta)
	if not _typing:
		return
	_elapsed += delta
	var count := Typewriter.visible_count(_times, _elapsed)
	if count > _shown:
		for i in range(_shown, count):
			var ch := _text.text[i]
			if ch.strip_edges() != "":
				Events.speaker_blip.emit(_who, ch)
		_shown = count
		_text.visible_characters = count
	if _shown >= _text.text.length():
		_text.visible_characters = -1
		_finish_typing()


func _finish_typing() -> void:
	_typing = false
	if _choices.is_empty():
		_hint.visible = true
		return
	for i in _choices.size():
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, str((_choices[i] as Dictionary).get("text", ""))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_pick.bind(i))
		_choice_box.add_child(b)


func _pick(index: int) -> void:
	if _choices.is_empty() or _typing:
		return
	_choices = []
	_clear_choices()
	choice_selected.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _guard > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_4 and not _typing and not _choices.is_empty():
			if k - KEY_1 < _choices.size():
				_pick(k - KEY_1)
				get_viewport().set_input_as_handled()
			return
	var pressed: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		skip_typing()
	elif _choices.is_empty():
		advance_requested.emit()


func _clear_choices() -> void:
	for c in _choice_box.get_children():
		c.queue_free()


func _display_name(who: String) -> String:
	return who.replace("_", " ").capitalize()
