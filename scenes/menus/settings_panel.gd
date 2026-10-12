class_name SettingsPanel
extends VBoxContainer
## Settings UI built in code: volume, mouse sensitivity, quality, Reduced Motion, Assist + a controls cheat sheet. (F-06)
##
## Reusable: PauseMenu shows it, and the title screen (F-13) can add `SettingsPanel.new()` anywhere. Every change goes
## through GameSettings.set_value (applied + saved immediately). Emits `back_requested` for its Back button.
## Works while the tree is paused (the owner should be PROCESS_MODE_ALWAYS or inside the PauseMenu layer).

## The Back button was pressed.
signal back_requested

const ACCENT := Color(1.0, 0.86, 0.42)
const TEXT := Color(1.0, 0.97, 0.9)
const SENS_DEFAULT := 0.0022

var _volume: HSlider
var _volume_val: Label
var _sens: HSlider
var _sens_val: Label
var _quality: OptionButton
var _reduced: CheckButton
var _assist: CheckButton
var _syncing: bool = false


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	custom_minimum_size = Vector2(560, 0)
	_add_title("Settings")

	_volume = _add_slider("Volume", 0.0, 1.0, 0.05, func(v: float) -> void: GameSettings.set_value("volume", v))
	_volume_val = _last_value_label
	_sens = _add_slider("Mouse sensitivity", GameSettings.SENSITIVITY_MIN, GameSettings.SENSITIVITY_MAX, 0.0001,
		func(v: float) -> void: GameSettings.set_value("sensitivity", v))
	_sens_val = _last_value_label

	var qrow := HBoxContainer.new()
	var ql := _make_label("Quality", 22)
	ql.custom_minimum_size = Vector2(200, 0)
	qrow.add_child(ql)
	_quality = OptionButton.new()
	for q in GameSettings.QUALITY_VALUES:
		_quality.add_item(str(q).capitalize())
	_quality.add_theme_font_size_override("font_size", 20)
	_quality.item_selected.connect(func(i: int) -> void:
		if not _syncing:
			GameSettings.set_value("quality", GameSettings.QUALITY_VALUES[i]))
	qrow.add_child(_quality)
	add_child(qrow)

	_reduced = _add_check("Reduced Motion", "No screen shake, bobbing, colour fringing, pulsing or crawling edges.",
		func(on: bool) -> void: GameSettings.set_value("reduced_motion", on))
	_assist = _add_check("Assist", "Easier interactions: you can reach things from further away.",
		func(on: bool) -> void: GameSettings.set_value("assist", on))

	var help := _make_label("WASD move   Mouse look   E interact   Space jump   Esc pause\nHold Space to skip a cutscene", 16)
	help.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	var reset := _make_button("Reset to defaults")
	reset.pressed.connect(func() -> void: GameSettings.reset_to_defaults())
	var back := _make_button("Back")
	back.pressed.connect(func() -> void: back_requested.emit())
	buttons.add_child(reset)
	buttons.add_child(back)
	add_child(buttons)

	Events.settings_changed.connect(func(_k: String) -> void: refresh())
	refresh()


## Re-reads Game.settings into the controls (called on every Events.settings_changed).
func refresh() -> void:
	_syncing = true
	_volume.value = float(Game.settings.get("volume", 0.8))
	_volume_val.text = "%d%%" % roundi(_volume.value * 100.0)
	_sens.value = float(Game.settings.get("sensitivity", SENS_DEFAULT))
	_sens_val.text = "%.1f×" % (_sens.value / SENS_DEFAULT)
	_quality.select(maxi(0, GameSettings.QUALITY_VALUES.find(str(Game.settings.get("quality", "auto")))))
	_reduced.button_pressed = bool(Game.settings.get("reduced_motion", false))
	_assist.button_pressed = bool(Game.settings.get("assist", false))
	_syncing = false


var _last_value_label: Label

func _add_slider(title: String, lo: float, hi: float, step: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var l := _make_label(title, 22)
	l.custom_minimum_size = Vector2(200, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(240, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v: float) -> void:
		if not _syncing:
			on_change.call(v))
	row.add_child(s)
	_last_value_label = _make_label("", 20)
	_last_value_label.custom_minimum_size = Vector2(70, 0)
	_last_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_last_value_label)
	add_child(row)
	return s


func _add_check(title: String, hint: String, on_toggle: Callable) -> CheckButton:
	var box := VBoxContainer.new()
	var c := CheckButton.new()
	c.text = title
	c.add_theme_font_size_override("font_size", 22)
	c.toggled.connect(func(on: bool) -> void:
		if not _syncing:
			on_toggle.call(on))
	box.add_child(c)
	var h := _make_label(hint, 15)
	h.add_theme_color_override("font_color", Color(0.8, 0.76, 0.72))
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.custom_minimum_size = Vector2(520, 0)
	box.add_child(h)
	add_child(box)
	return c


func _add_title(text: String) -> void:
	var t := _make_label(text, 34)
	t.add_theme_color_override("font_color", ACCENT)
	add_child(t)


func _make_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT)
	return l


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(190, 44)
	return b
