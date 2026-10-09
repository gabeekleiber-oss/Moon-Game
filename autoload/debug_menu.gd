extends CanvasLayer
## Backtick (`) toggles: chapter select, flea slider, next chapter. Owner: Lead.
## Also: launch with `-- --chapter=5` to jump straight to a chapter.

var _panel: PanelContainer
var _flea_label: Label

func _ready() -> void:
	layer = 100
	_build()
	_panel.visible = false
	Events.flea_changed.connect(func(v, _d, _r): _flea_label.text = "Flea: %d" % int(v))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		_panel.visible = not _panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "DEBUG - chapter select"
	box.add_child(title)
	for c in ChapterManager.CHAPTERS:
		var b := Button.new()
		b.text = "%d. %s" % [c["id"], c["title"]]
		b.pressed.connect(func(): ChapterManager.go_to(c["id"]))
		box.add_child(b)
	_flea_label = Label.new()
	_flea_label.text = "Flea: 0"
	box.add_child(_flea_label)
	var slider := HSlider.new()
	slider.max_value = 100
	slider.custom_minimum_size = Vector2(200, 0)
	slider.value_changed.connect(func(v): Game.set_flea(v, "debug"))
	box.add_child(slider)
