extends CanvasLayer
## Backtick (`) toggles: act select (jumps anywhere, ignoring locks), Unreality slider (force the hidden value), next act.
## Also: launch with `-- --act=5 --unreality=0.6` to jump straight there. Debug tool only; the player never sees this.

var _panel: PanelContainer
var _label: Label
var _slider: HSlider


func _ready() -> void:
	layer = 100
	_build()
	_panel.visible = false
	Events.unreality_changed.connect(func(l: float, _d: float, _r: String) -> void: _refresh(l))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		_panel.visible = not _panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED


func _refresh(l: float) -> void:
	_label.text = "Unreality: %.2f (%s)" % [l, Unreality.band_name()]


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "DEBUG - act select"
	box.add_child(title)
	for a in Acts.ACTS:
		var b := Button.new()
		b.text = "%d. %s" % [a["id"], a["title"]]
		var id: int = a["id"]
		b.pressed.connect(func() -> void: Acts.go_to(id, true))
		box.add_child(b)
	_label = Label.new()
	_label.text = "Unreality: 0.00 (ordinary)"
	box.add_child(_label)
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.custom_minimum_size = Vector2(240, 0)
	_slider.value_changed.connect(func(v: float) -> void: Unreality.force(v))
	box.add_child(_slider)
