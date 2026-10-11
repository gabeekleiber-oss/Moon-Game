class_name TitleScreen
extends Node3D
## The title screen (F-13): the Moon hero shot (its eye slowly opens and follows the mouse), stars, the game title, a rhyme line and a
## menu: Begin / Chapters / Settings / Quit. Built entirely in code. Runs standalone with F6 (then picking a chapter just fades and shows a message).
##
## Flow: pick Begin (chapter 1) or a chapter -> the screen fades to black (Cutscene.fade_out) -> `chapter_chosen(id)` is emitted. The listener
## (scenes/main/main.gd) frees this node, calls ChapterManager.go_to(id) and fades back in.
## API: `show_panel("menu"|"chapters"|"settings")`, `current_panel()`, `choose_chapter(id)`, `menu_labels()`, `chapter_labels()`.
## Esc / ui_cancel steps back to the menu. The HUD is hidden while this screen exists and restored when it leaves. Reduced Motion: no blinking,
## no star drift, no camera sway. The title screen music is MusicScore.CHAPTER_VARIATION[0] (\"title\"); playing it is up to the music task.
signal chapter_chosen(id: int)

const TITLE := "I've Hung You From the Moon"
## PLACEHOLDER tagline, original text written by an agent, NOT from the source story. Replace with the story's own line (TODO_VERBATIM).
const RHYME_LINE := "Hung from the moon, and humming along."
const CREAM := Color(1.0, 0.97, 0.9)
const ACCENT := Color(1.0, 0.86, 0.42)
const INK := Color(0.1, 0.05, 0.15)
const UI_LAYER := 12     # above HUD (8), below the dialogue box (20) and the Cutscene fade (50)
## Seconds the fade to black takes after a choice (tests set 0).
var fade_seconds: float = 0.7

var _moon: MoonEye
var _cam: Camera3D
var _stars: MeshInstance3D
var _ui: CanvasLayer
var _panels: Dictionary = {}
var _panel: String = ""
var _menu_buttons: Array[Button] = []
var _chapter_buttons: Array[Button] = []
var _blink_timer: float = 4.0
var _busy: bool = false
var _hud_was_visible: bool = true


func _ready() -> void:
	_hud_was_visible = Hud.is_hud_visible()
	Hud.set_hud_visible(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_build_ui()
	show_panel("menu")
	await get_tree().create_timer(0.9).timeout
	if is_inside_tree() and _moon:
		_moon.open(2.4)


func _exit_tree() -> void:
	if Hud:
		Hud.set_hud_visible(_hud_was_visible)


func _process(delta: float) -> void:
	if _moon == null or _cam == null:
		return
	var reduced := _reduced_motion()
	if not reduced and _stars:
		_stars.rotate_y(delta * 0.01)
	if not reduced:
		_cam.position.x = sin(Time.get_ticks_msec() / 6000.0) * 0.25
	var mp := get_viewport().get_mouse_position()
	var origin := _cam.project_ray_origin(mp)
	var dir := _cam.project_ray_normal(mp)
	_moon.look_at_point(origin + dir * 40.0, 0.25)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(3.5, 7.0)
		if _moon.is_open() and not reduced:
			_moon.blink()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel") and _panel != "menu":
		show_panel("menu")
		get_viewport().set_input_as_handled()


## Shows one of the panels: "menu", "chapters" or "settings". Unknown names are ignored.
func show_panel(panel_name: String) -> void:
	if not _panels.has(panel_name):
		return
	_panel = panel_name
	for k: String in _panels:
		(_panels[k] as Control).visible = (k == panel_name)
	var first: Button = null
	if panel_name == "menu" and not _menu_buttons.is_empty():
		first = _menu_buttons[0]
	elif panel_name == "chapters" and not _chapter_buttons.is_empty():
		first = _chapter_buttons[0]
	if first and first.is_inside_tree():
		first.grab_focus()


## Name of the visible panel.
func current_panel() -> String:
	return _panel


## Labels of the main menu buttons, top to bottom.
func menu_labels() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _menu_buttons:
		out.append(b.text)
	return out


## Labels of the chapter buttons ("1  The Fourteenth of September", ...).
func chapter_labels() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _chapter_buttons:
		out.append(b.text)
	return out


## Fades to black, then emits `chapter_chosen(id)`. Ignored while already leaving. With no listener (standalone F6) it fades back in.
func choose_chapter(id: int) -> void:
	if _busy:
		return
	_busy = true
	await Cutscene.fade_out(fade_seconds)
	if chapter_chosen.get_connections().is_empty():
		Events.show_message.emit("Chapter %d chosen (title screen running standalone)." % id)
		await Cutscene.fade_in(fade_seconds)
		_busy = false
		return
	chapter_chosen.emit(id)


# ---- building ----

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.6)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-20, 25, 0)
	add_child(sun)
	_moon = MoonEye.new()
	_moon.radius = 8.5
	_moon.position = Vector3(12.5, 0.5, 0.0)
	add_child(_moon)
	_stars = _make_stars(320)
	add_child(_stars)
	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 26)
	add_child(_cam)
	_cam.make_current()
	_cam.look_at(Vector3(3.0, 0.2, 0.0))


## A shell of tiny dots (point primitives) around the camera; deterministic.
func _make_stars(n: int) -> MeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var pts := PackedVector3Array()
	var cols := PackedColorArray()
	for i in n:
		var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 0.6)).normalized()
		pts.append(v * rng.randf_range(70.0, 90.0))
		var b := rng.randf_range(0.5, 1.0)
		cols.append(Color(b, b, minf(1.0, b + 0.1)))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.use_point_size = true
	mat.point_size = 2.5
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Stars"
	return mi


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = UI_LAYER
	add_child(_ui)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 72)
	root.add_theme_constant_override("margin_top", 64)
	root.add_theme_constant_override("margin_bottom", 56)
	root.add_theme_constant_override("margin_right", 48)
	_ui.add_child(root)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_theme_constant_override("separation", 10)
	root.add_child(col)

	var title := _label(TITLE, 54, CREAM)
	title.custom_minimum_size = Vector2(560, 0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	col.add_child(_label(RHYME_LINE, 24, ACCENT))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 36)
	col.add_child(gap)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.custom_minimum_size = Vector2(320, 0)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(menu)
	_panels["menu"] = menu
	_menu_buttons.append(_button(menu, "Begin", func() -> void: choose_chapter(1)))
	_menu_buttons.append(_button(menu, "Chapters", func() -> void: show_panel("chapters")))
	_menu_buttons.append(_button(menu, "Settings", func() -> void: show_panel("settings")))
	_menu_buttons.append(_button(menu, "Quit", func() -> void: get_tree().quit()))

	var chapters := VBoxContainer.new()
	chapters.add_theme_constant_override("separation", 6)
	chapters.custom_minimum_size = Vector2(520, 0)
	chapters.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(chapters)
	_panels["chapters"] = chapters
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chapters.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for c: Dictionary in ChapterManager.CHAPTERS:
		var id: int = c["id"]
		_chapter_buttons.append(_button(list, "%d  %s" % [id, c["title"]], func() -> void: choose_chapter(id), 20))
	var back := _button(chapters, "Back", func() -> void: show_panel("menu"), 20)
	_chapter_buttons.append(back)

	var settings := SettingsPanel.new()
	settings.back_requested.connect(func() -> void: show_panel("menu"))
	col.add_child(settings)
	_panels["settings"] = settings


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 6)
	return l


func _button(parent: Control, text: String, on_press: Callable, size: int = 28) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", ACCENT)
	b.add_theme_color_override("font_focus_color", ACCENT)
	b.add_theme_color_override("font_pressed_color", ACCENT)
	var normal := _box(Color(INK.r, INK.g, INK.b, 0.45), Color(0, 0, 0, 0))
	var hot := _box(Color(INK.r, INK.g, INK.b, 0.8), ACCENT)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 3
	s.set_corner_radius_all(4)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _reduced_motion() -> bool:
	return bool(Game.settings.get("reduced_motion", false))
