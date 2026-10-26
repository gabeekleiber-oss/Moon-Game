extends CanvasLayer
## Autoload `PauseMenu`: Esc pause menu (Resume / Settings / Quit) and a quiet toast for in-world messages (Events.show_message).
##
## - Esc opens/closes; inside Settings it steps back instead. Ignored during a cutscene.
## - Pausing sets get_tree().paused = true (this node and its UI are PROCESS_MODE_ALWAYS) and shows the mouse;
##   closing restores whatever mouse mode was active before.
## - Loads and applies the saved settings file once at boot (GameSettingsScript.load_and_apply()).
## Script API: PauseMenu.open_pause(), PauseMenu.close(), PauseMenu.is_open(). Event: Events.game_paused(bool).

const SettingsPanelScript = preload("res://scenes/menus/settings_panel.gd")
const GameSettingsScript = preload("res://scenes/menus/game_settings.gd")
const LAYER := 60
const ACCENT := Color(1.0, 0.86, 0.42)

## "" (closed), "pause" or "settings".
var _mode: String = ""
var _prev_mouse: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

var _root: Control
var _panel: PanelContainer
var _pause_box: VBoxContainer
var _settings: SettingsPanelScript
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween


func _init() -> void:
	layer = LAYER
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var first_launch := GameSettingsScript.needs_first_run_setup()
	GameSettingsScript.load_and_apply()
	_build()
	_show_mode("")
	# Exported games offer a first-run settings check; tests and editor sessions do not.
	if first_launch and OS.has_feature("standalone") and OS.get_cmdline_user_args().has("--setup"):
		call_deferred("_open", "settings")


## True while the pause menu or settings is on screen.
func is_open() -> bool:
	return _mode != ""


## Opens the pause menu (does nothing during a cutscene or if already open).
func open_pause() -> void:
	if _mode == "" and not Cutscene.is_active():
		_open("pause")


## Closes whatever is open and resumes the game.
func close() -> void:
	if _mode != "":
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if Cutscene.is_active():
			return
		get_viewport().set_input_as_handled()
		match _mode:
			"":
				_open("pause")
			"settings":
				_show_mode("pause")
			_:
				_close()


func _open(mode: String) -> void:
	_prev_mouse = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_mode(mode)
	Events.game_paused.emit(true)


func _close() -> void:
	_show_mode("")
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse
	Events.game_paused.emit(false)


func _show_mode(mode: String) -> void:
	_mode = mode
	_root.visible = mode != ""
	_pause_box.visible = mode == "pause"
	_settings.visible = mode == "settings"


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.06, 0.14, 0.96)
	style.border_color = ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var stack := VBoxContainer.new()
	_panel.add_child(stack)

	_pause_box = VBoxContainer.new()
	_pause_box.add_theme_constant_override("separation", 14)
	_pause_box.custom_minimum_size = Vector2(340, 0)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", ACCENT)
	_pause_box.add_child(title)
	_pause_box.add_child(_button("Resume", _close))
	_pause_box.add_child(_button("Settings", func() -> void: _show_mode("settings")))
	_pause_box.add_child(_button("Quit", func() -> void: get_tree().quit()))
	stack.add_child(_pause_box)

	_settings = SettingsPanelScript.new()
	_settings.back_requested.connect(func() -> void: _show_mode("pause"))
	stack.add_child(_settings)

	_build_toast()
	Events.show_message.connect(_on_message)


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(0, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.06, 0.82)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	_toast.add_theme_stylebox_override("panel", style)
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 22)
	_toast_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	_toast.add_child(_toast_label)
	add_child(_toast)


## Briefly shows a line of in-world text (an interactable's response) near the top of the screen, even when not paused.
func _on_message(text: String) -> void:
	_toast_label.text = text
	_toast.reset_size()
	_toast.position.x = (get_viewport().get_visible_rect().size.x - _toast.size.x) * 0.5
	_toast.modulate.a = 1.0
	_toast.visible = true
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(0, 52)
	b.pressed.connect(on_press)
	return b
