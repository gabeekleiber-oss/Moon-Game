class_name NotepadView
extends VBoxContainer
## The Treasure Notepad page: a handwritten-looking list of owned items grouped by room, each with its value, plus a total. (F-06)
##
## Reads `Game.notepad` (entries {id, name, value, room}) and `Game.notepad_total()`; never writes to them.
## Reusable: PauseMenu shows it on Q; any scene can add `NotepadView.new()`. Call `refresh()` after the list changes
## (it also refreshes itself on `Events.notepad_item_added` and whenever it becomes visible).
## Value unit is not defined in the docs, so values are shown as plain numbers.

const PAPER := Color(0.96, 0.92, 0.80)
const INK := Color(0.16, 0.13, 0.30)
const INK_SOFT := Color(0.38, 0.33, 0.52)
const RULE := Color(0.62, 0.57, 0.74, 0.55)

var _list: VBoxContainer
var _total: Label
var _count: Label


func _ready() -> void:
	custom_minimum_size = Vector2(560, 0)
	add_theme_constant_override("separation", 10)
	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(4)
	style.set_content_margin_all(24)
	style.shadow_size = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	paper.add_theme_stylebox_override("panel", style)
	add_child(paper)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	paper.add_child(page)
	var title := _label("Treasure Notepad", 34, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)
	_count = _label("", 18, INK_SOFT)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_count)
	page.add_child(_rule())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	page.add_child(_rule())
	var total_row := HBoxContainer.new()
	var tl := _label("Total", 28, INK)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_row.add_child(tl)
	_total = _label("0", 28, INK)
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_row.add_child(_total)
	page.add_child(total_row)

	Events.notepad_item_added.connect(func(_item: Dictionary) -> void: refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			refresh())
	refresh()


## Rebuilds the list from `Game.notepad`: rooms in the order they first appear, items in the order they were written.
func refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var rooms: Array[String] = []
	for item in Game.notepad:
		var room := str(item.get("room", ""))
		if not rooms.has(room):
			rooms.append(room)
	if rooms.is_empty():
		var empty := _label("Nothing written down yet.", 22, INK_SOFT)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	for room in rooms:
		var header := _label(room if room != "" else "Elsewhere", 24, INK)
		_list.add_child(header)
		for item in Game.notepad:
			if str(item.get("room", "")) == room:
				_list.add_child(_row(str(item.get("name", "?")), int(item.get("value", 0))))
	var n := Game.notepad.size()
	_count.text = "%d item%s" % [n, "" if n == 1 else "s"]
	_total.text = format_value(Game.notepad_total())


## Formats a value with thousands separators (12500 -> "12,500").
static func format_value(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if v < 0 else "") + s + out


func _row(item_name: String, value: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var indent := Control.new()
	indent.custom_minimum_size = Vector2(16, 0)
	row.add_child(indent)
	var n := _label(item_name, 21, INK)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(n)
	var v := _label(format_value(value), 21, INK_SOFT)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = RULE
	r.custom_minimum_size = Vector2(0, 2)
	return r
