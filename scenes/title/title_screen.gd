class_name TitleScreen
extends Node3D
## Title screen (S-11): the code-made MoonEye as backdrop, then Begin / Continue / Settings / Credits / Quit.
##
## Begin starts a new game via `SaveGame.new_game()` (asking first if a save exists, because Begin replaces it).
## Continue is enabled only when `SaveGame.has_save()`. No HUD, no meters. Reduced Motion turns off random blinking.
## Runnable standalone (F6). Frees itself once an act has started.

## Emitted just before the screen frees itself because a game started.
signal game_started

const ACCENT := Color(1.0, 0.86, 0.42)
const TEXT := Color(1.0, 0.97, 0.9)
const TITLE_TEXT := "I've Hung You From the Moon"
const CREDITS_LINES: Array[String] = [
	"Adapted from a surreal, rhyming, darkly comic short story.",
	"Built in Godot 4.3.",
	"Placeholder credits: the full list is filled in by the Z-tasks.",
]

var _moon: MoonEye
var _cam: Camera3D
var _blink_timer: float = 4.0
var _starting: bool = false
var _layer: CanvasLayer
var _menu_box: VBoxContainer
var _confirm_box: VBoxContainer
var _settings: SettingsPanel
var _credits_box: VBoxContainer
var _begin_button: Button
var _continue_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_backdrop()
	_build_ui()
	_show_panel("menu")
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(_moon):
		_moon.open(2.2)


## Re-checks the save file (call after anything that might have created or removed it).
func refresh() -> void:
	_continue_button.disabled = not SaveGame.has_save()


## Which panel is showing: "menu", "confirm", "settings" or "credits".
func panel() -> String:
	if _confirm_box.visible:
		return "confirm"
	if _settings.visible:
		return "settings"
	if _credits_box.visible:
		return "credits"
	return "menu"


## What the Begin button does (public so tests can drive it without a mouse).
func begin_pressed() -> void:
	if _starting:
		return
	if SaveGame.has_save():
		_show_panel("confirm")
	else:
		await start_new()


## Starts a fresh game, replacing any save.
func start_new() -> void:
	if _starting:
		return
	_starting = true
	await SaveGame.new_game()
	game_started.emit()
	queue_free()


## Loads the save. Returns false (and stays on the title) if there is no valid save.
func continue_pressed() -> bool:
	if _starting or not SaveGame.has_save():
		refresh()
		return false
	_starting = true
	var ok: bool = await SaveGame.continue_game()
	if not ok:
		_starting = false
		refresh()
		return false
	game_started.emit()
	queue_free()
	return true


func _process(delta: float) -> void:
	if _moon == null or _cam == null:
		return
	var mp := get_viewport().get_mouse_position()
	var origin := _cam.project_ray_origin(mp)
	var dir := _cam.project_ray_normal(mp)
	_moon.look_at_point(origin + dir * 40.0, 0.25)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(3.5, 7.0)
		if _moon.is_open() and not bool(Game.settings.get("reduced_motion", false)):
			_moon.blink()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel() != "menu":
		_show_panel("menu")
		get_viewport().set_input_as_handled()


func _build_backdrop() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.06)
	env.ambient_light_color = Color(0.4, 0.45, 0.6)
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 25, 0)
	add_child(sun)
	_moon = MoonEye.new()
	_moon.position = Vector3(11.0, 0.5, 0.0)
	add_child(_moon)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 28)
	add_child(_cam)
	_cam.make_current()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 96)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_bottom", 72)
	margin.add_theme_constant_override("margin_right", 96)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 28)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.add_child(stack)
	var title := Label.new()
	title.text = TITLE_TEXT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(560, 0)
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", ACCENT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 12)
	_menu_box.custom_minimum_size = Vector2(320, 0)
	_menu_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_begin_button = _button("Begin", begin_pressed)
	_continue_button = _button("Continue", func() -> void: await continue_pressed())
	_menu_box.add_child(_begin_button)
	_menu_box.add_child(_continue_button)
	_menu_box.add_child(_button("Settings", func() -> void: _show_panel("settings")))
	_menu_box.add_child(_button("Credits", func() -> void: _show_panel("credits")))
	_menu_box.add_child(_button("Quit", func() -> void: get_tree().quit()))
	stack.add_child(_menu_box)

	_confirm_box = VBoxContainer.new()
	_confirm_box.add_theme_constant_override("separation", 12)
	_confirm_box.custom_minimum_size = Vector2(420, 0)
	_confirm_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var ask := Label.new()
	ask.text = "Start over? Beginning again replaces your saved game."
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.add_theme_font_size_override("font_size", 24)
	ask.add_theme_color_override("font_color", TEXT)
	_confirm_box.add_child(ask)
	_confirm_box.add_child(_button("Start over", func() -> void: await start_new()))
	_confirm_box.add_child(_button("Keep my save", func() -> void: _show_panel("menu")))
	stack.add_child(_confirm_box)

	_settings = SettingsPanel.new()
	_settings.back_requested.connect(func() -> void: _show_panel("menu"))
	stack.add_child(_settings)

	_credits_box = VBoxContainer.new()
	_credits_box.add_theme_constant_override("separation", 10)
	_credits_box.custom_minimum_size = Vector2(520, 0)
	for line in CREDITS_LINES:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", TEXT)
		_credits_box.add_child(l)
	_credits_box.add_child(_button("Back", func() -> void: _show_panel("menu")))
	stack.add_child(_credits_box)


func _show_panel(which: String) -> void:
	_menu_box.visible = which == "menu"
	_confirm_box.visible = which == "confirm"
	_settings.visible = which == "settings"
	_credits_box.visible = which == "credits"
	if which == "menu":
		refresh()
		var first: Button = _continue_button if not _continue_button.disabled else _begin_button
		first.grab_focus.call_deferred()
		if not _continue_button.disabled:
			_begin_button.focus_neighbor_bottom = _continue_button.get_path()


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 26)
	b.custom_minimum_size = Vector2(0, 52)
	b.pressed.connect(on_press)
	return b
