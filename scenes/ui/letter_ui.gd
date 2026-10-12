class_name LetterUI
extends CanvasLayer
## Full-screen damp letter (Act 1). The text is the verbatim letter from the source story (data/text/letter.txt).
##
## Usage: `var ui := LetterUI.new(); add_child(ui); ui.open(); await ui.closed`.
## The first press of E / Space / Enter / click reveals the whole letter, the next press closes it.
## `advance()` does the same from code (tests). `reveal_seconds` is how long the lines take to appear on their own.

## Emitted after the letter has been dismissed and the layer hidden.
signal closed

const TEXT_PATH := "res://data/text/letter.txt"

## Seconds for the letter to write itself out (0 = instantly).
@export var reveal_seconds: float = 12.0

var _root: Control
var _paper: PanelContainer
var _label: Label
var _hint: Label
var _tween: Tween
var _open: bool = false
var _prev_mouse: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func _init() -> void:
	layer = 40
	visible = false


func _ready() -> void:
	_build()


## True while the letter is on screen.
func is_open() -> bool:
	return _open


## True once every character of the letter is showing.
func is_fully_revealed() -> bool:
	return _label != null and _label.visible_ratio >= 1.0


## The letter text exactly as shown (verbatim from the story).
func letter_text() -> String:
	return _label.text if _label != null else ""


## Shows the letter: paper unfolds, text writes itself out.
func open() -> void:
	if _open:
		return
	if _label == null:
		_build()
	_open = true
	visible = true
	_prev_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_sfx("paper")
	_label.visible_ratio = 0.0
	_hint.modulate.a = 0.0
	_root.modulate.a = 0.0
	_paper.scale = Vector2(0.92, 0.92)
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_root, "modulate:a", 1.0, 0.35)
	_tween.tween_property(_paper, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if reveal_seconds <= 0.0:
		_label.visible_ratio = 1.0
		_hint.modulate.a = 1.0
	else:
		_tween.chain().tween_property(_label, "visible_ratio", 1.0, reveal_seconds)
		_tween.tween_property(_hint, "modulate:a", 1.0, 0.6)


## First call: reveal everything. Second call: close. Safe to call any time.
func advance() -> void:
	if not _open:
		return
	if not is_fully_revealed():
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_root.modulate.a = 1.0
		_paper.scale = Vector2.ONE
		_label.visible_ratio = 1.0
		_hint.modulate.a = 1.0
		return
	close()


## Hides the letter and emits `closed`.
func close() -> void:
	if not _open:
		return
	_open = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	if _prev_mouse == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = event.is_action("interact") or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if pressed:
		get_viewport().set_input_as_handled()
		advance()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.08, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	_paper = PanelContainer.new()
	_paper.pivot_offset = Vector2(340, 280)
	_paper.rotation = deg_to_rad(-1.2)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.86, 0.66)          # a slightly damp, sun-baked cream
	sb.border_color = Color(0.62, 0.5, 0.3)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(28)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	_paper.add_theme_stylebox_override("panel", sb)
	center.add_child(_paper)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_paper.add_child(box)
	_label = Label.new()
	_label.text = _read_text()
	_label.custom_minimum_size = Vector2(640, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 19)
	_label.add_theme_color_override("font_color", Color(0.17, 0.12, 0.08))
	box.add_child(_label)
	_hint = Label.new()
	_hint.text = "[E] put it down"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))
	box.add_child(_hint)


func _read_text() -> String:
	if not FileAccess.file_exists(TEXT_PATH):
		push_error("LetterUI: missing %s" % TEXT_PATH)
		return "TODO_VERBATIM"
	return FileAccess.get_file_as_string(TEXT_PATH).strip_edges()
