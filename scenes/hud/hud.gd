extends CanvasLayer
## Autoload `Hud`: the always-on screen UI, built in code. (F-03)
##
## Nothing to set up: it listens to the Events bus.
##   Events.objective_set(text)        -> objective line (top centre)
##   Events.show_message(text)         -> short toast under the objective
##   Events.caption(who, text)         -> caption box + speaker tag (bottom centre), ONLY while no dialogue box is up
##   Events.flea_changed / heart_changed -> flea jar + 4 hearts (top left) and floating "+3 fleas" ticks
## Script API: `Hud.caption(who, text, seconds)`, `Hud.clear_caption()`, `Hud.set_hud_visible(bool)` (cutscenes hide it).
## Reduced Motion (Game.settings.reduced_motion) turns off flea hopping, heart pulses and rising ticks (they just fade).
## Layers: HUD 8 < InteractionHud 10 < DialogueBox 20.

const HEART_ORDER: Array[String] = ["elsa", "mary_sue", "frank", "self"]
const HEART_NAMES := {"elsa": "Elsa", "mary_sue": "Mary Sue", "frank": "Frank", "self": "Self"}
const TICK_LIFETIME := 1.3
const MAX_TICKS := 8
const TOAST_SECONDS := 3.0
const CAPTION_MIN_SECONDS := 2.5
const CAPTION_SECONDS_PER_CHAR := 0.05

const INK := Color(0.1, 0.05, 0.15, 0.9)
const CREAM := Color(1.0, 0.95, 0.8)

var _root: Control
var _objective: Label
var _toast: Label
var _caption_panel: PanelContainer
var _caption_who: Label
var _caption_text: Label
var _jar: _FleaJar
var _hearts: _HeartRow
var _tick_layer: Control
var _objective_tween: Tween
var _toast_tween: Tween
var _caption_token: int = 0
var _toast_token: int = 0


func _init() -> void:
	layer = 8
	name = "Hud"


func _ready() -> void:
	_root = Control.new()
	_root.name = "HudRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_meters()
	_build_objective()
	_build_caption()
	_tick_layer = Control.new()
	_tick_layer.name = "Ticks"
	_tick_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tick_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_tick_layer)

	_jar.set_level(Game.flea, true)
	for who in HEART_ORDER:
		_hearts.set_value(who, int(Game.hearts.get(who, 0)), true)

	Events.objective_set.connect(_on_objective_set)
	Events.show_message.connect(_on_show_message)
	Events.caption.connect(_on_caption)
	Events.dialogue_started.connect(func(_id: String) -> void: clear_caption())
	Events.flea_changed.connect(_on_flea_changed)
	Events.heart_changed.connect(_on_heart_changed)


# ---------------------------------------------------------------- public API

## Shows a caption (speaker tag + text) for `seconds` (default: scales with text length). Empty `who` hides the tag.
func caption(who: String, text: String, seconds: float = -1.0) -> void:
	if text == "":
		clear_caption()
		return
	_caption_token += 1
	var token := _caption_token
	_caption_who.text = _display_name(who)
	_caption_who.visible = who != ""
	_caption_text.text = text
	_caption_panel.visible = true
	var hold := seconds if seconds > 0.0 else maxf(CAPTION_MIN_SECONDS, text.length() * CAPTION_SECONDS_PER_CHAR)
	await get_tree().create_timer(hold).timeout
	if token == _caption_token:
		_caption_panel.visible = false


## Hides the caption box now.
func clear_caption() -> void:
	_caption_token += 1
	_caption_panel.visible = false


## Shows or hides the whole HUD (cutscenes, title screen). The interaction prompt and dialogue box are separate.
func set_hud_visible(value: bool) -> void:
	_root.visible = value


## True while the caption box is on screen.
func is_caption_visible() -> bool:
	return _caption_panel.visible


## The text currently in the objective line.
func objective_text() -> String:
	return _objective.text


# ---------------------------------------------------------------- building

func _build_meters() -> void:
	var box := HBoxContainer.new()
	box.name = "Meters"
	box.position = Vector2(20, 16)
	box.add_theme_constant_override("separation", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)
	_jar = _FleaJar.new()
	_jar.name = "FleaJar"
	box.add_child(_jar)
	_hearts = _HeartRow.new()
	_hearts.name = "Hearts"
	_hearts.setup(HEART_ORDER, HEART_NAMES)
	box.add_child(_hearts)


func _build_objective() -> void:
	_objective = _make_label(22)
	_objective.name = "Objective"
	_objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective.anchor_left = 0.5
	_objective.anchor_right = 0.5
	_objective.offset_left = -420.0
	_objective.offset_right = 420.0
	_objective.offset_top = 14.0
	_objective.offset_bottom = 48.0
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.visible = false
	_root.add_child(_objective)

	_toast = _make_label(20)
	_toast.name = "Toast"
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.offset_left = -420.0
	_toast.offset_right = 420.0
	_toast.offset_top = 52.0
	_toast.offset_bottom = 84.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_toast.modulate.a = 0.0
	_root.add_child(_toast)


func _build_caption() -> void:
	_caption_panel = PanelContainer.new()
	_caption_panel.name = "CaptionBox"
	_caption_panel.anchor_left = 0.5
	_caption_panel.anchor_right = 0.5
	_caption_panel.anchor_top = 1.0
	_caption_panel.anchor_bottom = 1.0
	_caption_panel.offset_left = -400.0
	_caption_panel.offset_right = 400.0
	_caption_panel.offset_top = -150.0
	_caption_panel.offset_bottom = -40.0
	_caption_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.06, 0.14, 0.82)
	style.border_color = Color(0.85, 0.7, 0.35, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	_caption_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_caption_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.add_child(vbox)
	_caption_who = Label.new()
	_caption_who.add_theme_font_size_override("font_size", 18)
	_caption_who.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	_caption_who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_caption_who)
	_caption_text = Label.new()
	_caption_text.add_theme_font_size_override("font_size", 22)
	_caption_text.add_theme_color_override("font_color", CREAM)
	_caption_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_caption_text)


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", CREAM)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _display_name(who: String) -> String:
	if HEART_NAMES.has(who):
		return str(HEART_NAMES[who])
	return who.replace("_", " ").capitalize()


func _reduced_motion() -> bool:
	return bool(Game.settings.get("reduced_motion", false))


# ---------------------------------------------------------------- event handlers

func _on_objective_set(text: String) -> void:
	_objective.text = text
	_objective.visible = text != ""
	if _objective_tween != null:
		_objective_tween.kill()
	if text == "":
		return
	_objective.modulate.a = 1.0
	if _reduced_motion():
		return
	_objective.modulate.a = 0.0
	_objective_tween = create_tween()
	_objective_tween.tween_property(_objective, "modulate:a", 1.0, 0.6)


func _on_show_message(text: String) -> void:
	_toast_token += 1
	var token := _toast_token
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.text = text
	_toast.modulate.a = 1.0
	await get_tree().create_timer(TOAST_SECONDS).timeout
	if token != _toast_token:
		return
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _on_caption(who: String, text: String) -> void:
	if Dialogue.is_active():
		return  # the dialogue box already shows this line
	caption(who, text)


func _on_flea_changed(value: float, delta: float, _reason: String) -> void:
	_jar.set_level(value, false)
	if absf(delta) >= 0.5:
		_spawn_tick("%+d fleas" % int(roundf(delta)), _jar.global_position + Vector2(_jar.size.x * 0.5, _jar.size.y), delta > 0.0)


func _on_heart_changed(who: String, value: int, delta: int) -> void:
	_hearts.set_value(who, value, false)
	if delta != 0:
		_spawn_tick("%+d %s" % [delta, _display_name(who)], _hearts.heart_global_position(who), delta > 0)


func _spawn_tick(text: String, at: Vector2, good: bool) -> void:
	while _tick_layer.get_child_count() >= MAX_TICKS:
		var old := _tick_layer.get_child(0)
		_tick_layer.remove_child(old)   # remove now: queue_free alone is deferred, so a burst would exceed the cap
		old.queue_free()
	var l := _make_label(20)
	l.text = text
	l.add_theme_color_override("font_color", Color(0.65, 1.0, 0.6) if good else Color(1.0, 0.45, 0.4))
	l.position = at - Vector2(40, 0)
	_tick_layer.add_child(l)
	var tw := create_tween()
	if _reduced_motion():
		tw.tween_property(l, "modulate:a", 0.0, TICK_LIFETIME * 0.6)
	else:
		tw.set_parallel(true)
		tw.tween_property(l, "position:y", l.position.y + (-36.0 if good else 36.0), TICK_LIFETIME)
		tw.tween_property(l, "modulate:a", 0.0, TICK_LIFETIME).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)


# ---------------------------------------------------------------- widgets

## Glass jar that fills with fleas. `set_level(0..100)`.
class _FleaJar extends Control:
	const W := 70.0
	const H := 104.0
	var target: float = 0.0
	var shown: float = 0.0
	var _t: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(W, H + 22.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_level(value: float, instant: bool) -> void:
		target = clampf(value, 0.0, 100.0)
		if instant or bool(Game.settings.get("reduced_motion", false)):
			shown = target
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if not is_equal_approx(shown, target):
			shown = move_toward(shown, target, maxf(30.0 * delta, absf(target - shown) * 4.0 * delta))
		if shown > 0.0 or target > 0.0:
			queue_redraw()

	func _fill_colour() -> Color:
		return Color(0.95, 0.75, 0.25).lerp(Color(0.9, 0.25, 0.2), clampf((shown - 40.0) / 50.0, 0.0, 1.0))

	func _draw() -> void:
		var body := Rect2(8, 14, W - 16, H - 14)
		var glass := Color(0.75, 0.9, 1.0, 0.16)
		draw_rect(body, glass, true)
		var fill_h := body.size.y * shown / 100.0
		if fill_h > 0.5:
			var fill := Rect2(body.position.x, body.end.y - fill_h, body.size.x, fill_h)
			var c := _fill_colour()
			c.a = 0.55
			draw_rect(fill, c, true)
			var dots := int(shown / 100.0 * 26.0)
			var hop := not bool(Game.settings.get("reduced_motion", false))
			for i in dots:
				var px := body.position.x + 6.0 + fmod(float(i) * 37.0 + 11.0, body.size.x - 12.0)
				var py := body.end.y - 6.0 - fmod(float(i) * 23.0 + 5.0, maxf(fill_h - 8.0, 1.0))
				if hop:
					py -= absf(sin(_t * 5.0 + float(i) * 1.7)) * 3.0
				py = clampf(py, fill.position.y + 2.0, body.end.y - 3.0)
				draw_circle(Vector2(px, py), 1.8, Color(0.12, 0.06, 0.08, 0.95))
		draw_rect(body, Color(0.95, 0.97, 1.0, 0.9), false, 2.0)
		draw_rect(Rect2(4, 8, W - 8, 8), Color(0.85, 0.7, 0.35), true)   # lid
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, H + 16.0), "FLEAS %d" % int(roundf(shown)), HORIZONTAL_ALIGNMENT_CENTER, W, 13, Color(1, 0.95, 0.8))


## Four hearts (one per household member), each filled value/10 from the bottom.
class _HeartRow extends Control:
	const CELL := 58.0
	const HEART := 36.0
	var _order: Array[String] = []
	var _names := {}
	var _shown := {}
	var _pulse := {}
	var _flash := {}

	func setup(order: Array[String], names: Dictionary) -> void:
		_order = order
		_names = names
		custom_minimum_size = Vector2(CELL * order.size(), 74.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for who in order:
			_shown[who] = 0
			_pulse[who] = 0.0
			_flash[who] = 0.0

	func set_value(who: String, value: int, instant: bool) -> void:
		if not _shown.has(who):
			return
		var old: int = _shown[who]
		_shown[who] = value
		if not instant and value != old and not bool(Game.settings.get("reduced_motion", false)):
			_pulse[who] = 1.0
		_flash[who] = 1.0 if (not instant and value != old) else 0.0
		queue_redraw()

	func value_of(who: String) -> int:
		return int(_shown.get(who, 0))

	func heart_global_position(who: String) -> Vector2:
		var i := maxi(_order.find(who), 0)
		return global_position + Vector2(CELL * float(i) + CELL * 0.5, HEART + 8.0)

	func _process(delta: float) -> void:
		var busy := false
		for who in _order:
			if _pulse[who] > 0.0 or _flash[who] > 0.0:
				busy = true
				_pulse[who] = maxf(_pulse[who] - delta * 3.0, 0.0)
				_flash[who] = maxf(_flash[who] - delta * 2.0, 0.0)
		if busy:
			queue_redraw()

	static func heart_points(centre: Vector2, size: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 40:
			var t := TAU * float(i) / 40.0
			var x := 16.0 * pow(sin(t), 3.0)
			var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
			pts.append(centre + Vector2(x, y) * (size / 34.0))
		return pts

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		for i in _order.size():
			var who := _order[i]
			var scale_f: float = 1.0 + 0.18 * float(_pulse[who])
			var centre := Vector2(CELL * float(i) + CELL * 0.5, HEART * 0.5 + 6.0)
			var poly := heart_points(centre, HEART * scale_f)
			draw_colored_polygon(poly, Color(0.18, 0.1, 0.16, 0.7))
			var frac := clampf(float(_shown[who]) / 10.0, 0.0, 1.0)
			if frac > 0.0:
				var top: float = centre.y + HEART * 0.5 * scale_f - HEART * scale_f * frac
				var clip := PackedVector2Array([
					Vector2(centre.x - HEART, top), Vector2(centre.x + HEART, top),
					Vector2(centre.x + HEART, centre.y + HEART), Vector2(centre.x - HEART, centre.y + HEART)])
				var red := Color(0.86, 0.2, 0.28).lerp(Color(1, 1, 1), 0.35 * float(_flash[who]))
				for piece in Geometry2D.intersect_polygons(poly, clip):
					draw_colored_polygon(piece, red)
			var outline := poly.duplicate()
			outline.append(poly[0])
			draw_polyline(outline, Color(1, 0.92, 0.85, 0.9), 2.0)
			var label := str(_names.get(who, who))
			draw_string(font, Vector2(CELL * float(i), HEART + 30.0), label, HORIZONTAL_ALIGNMENT_CENTER, CELL, 12, Color(1, 0.95, 0.8))
