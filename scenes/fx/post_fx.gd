extends Node
## Autoload `PostFX`: the full-screen post pass (vignette, grain, chroma, grade, bloom approx, flea overlay). (F-04)
##
## It draws a ColorRect with scenes/fx/post_fx.gdshader on a CanvasLayer BELOW the HUD (layer 5; HUD/dialogue are
## 10+), so only the 3D world is graded. It runs by itself:
##  - Events.chapter_started(id) -> eases to GradeTable.for_chapter(id)
##  - Events.flea_changed        -> flea overlay (edge sparks, vignette pulse, gold motes at 70+), smoothed
##  - Game.settings: `reduced_motion` kills chroma, grain flicker, vignette pulse and edge crawl;
##    `quality` == "low" turns the whole pass off. Re-read twice a second; call `apply_settings()` to force.
## From chapter scripts:
##     PostFX.set_grade("ch07_kitchen", 2.0)          # named grade (GradeTable.names()), eased over 2 s
##     PostFX.set_grade({"saturation": 0.4}, 1.0)     # or a partial dictionary on top of the current grade
##     PostFX.set_param("vignette_strength", 0.8)     # one uniform, immediately (until the next grade change)
##     PostFX.set_enabled(false)                      # e.g. for a title card

const SHADER := preload("res://scenes/fx/post_fx.gdshader")
const CHROMA_DEFAULT := 0.0012
const GRAIN_FPS := 12.0          # grain re-rolls 12x/s (fine film noise, not a flash; Reduced Motion freezes it)
const SETTINGS_POLL := 0.5

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _grade: Dictionary = GradeTable.NEUTRAL.duplicate()
var _grade_name: String = "neutral"
var _tween: Tween
var _flea: float = 0.0
var _flea_target: float = 0.0
var _time: float = 0.0
var _poll: float = 0.0
var _enabled: bool = true
var _reduced_motion: bool = false
var _quality: String = "auto"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # keep pulsing while the game is paused
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	_layer = CanvasLayer.new()
	_layer.layer = 5
	_layer.name = "PostFXLayer"
	_layer.add_child(_rect)
	add_child(_layer)
	_flea_target = clampf(Game.flea / 100.0, 0.0, 1.0)
	_flea = _flea_target
	_push_grade(_grade)
	apply_settings()
	Events.flea_changed.connect(func(value: float, _d: float, _r: String) -> void: _flea_target = clampf(value / 100.0, 0.0, 1.0))
	Events.chapter_started.connect(func(id: int) -> void: set_chapter(id))


## Eases to the default grade of chapter `id` (1-11) over `duration` seconds.
func set_chapter(id: int, duration: float = 1.5) -> void:
	_grade_name = GradeTable.CHAPTER_GRADE.get(id, "neutral")
	_ease_to(GradeTable.get_grade(_grade_name), duration)


## Eases to a named grade (see GradeTable.names()) or to a partial Dictionary of shader uniforms applied over
## the current grade, over `duration` seconds (0 = instant).
func set_grade(grade: Variant, duration: float = 1.5) -> void:
	if grade is String:
		_grade_name = grade
		_ease_to(GradeTable.get_grade(grade), duration)
	elif grade is Dictionary:
		var target := _grade.duplicate()
		target.merge(grade, true)
		_grade_name = "custom"
		_ease_to(target, duration)


## Name of the current grade ("custom" after a Dictionary grade).
func get_grade_name() -> String:
	return _grade_name


## Sets one shader uniform immediately (it is also stored, so it survives until the next grade change).
func set_param(param: String, value: Variant) -> void:
	_grade[param] = value
	_mat.set_shader_parameter(param, value)


## Turns the whole pass on/off (also off when quality is "low").
func set_enabled(on: bool) -> void:
	_enabled = on
	_update_visibility()


## True if the pass is currently drawn.
func is_enabled() -> bool:
	return _rect.visible


## Re-reads Game.settings (reduced_motion, quality). Called automatically twice a second.
func apply_settings() -> void:
	_reduced_motion = bool(Game.settings.get("reduced_motion", false))
	_quality = str(Game.settings.get("quality", "auto"))
	_mat.set_shader_parameter("chroma_amount", 0.0 if _reduced_motion else CHROMA_DEFAULT)
	_mat.set_shader_parameter("flea_motion", 0.0 if _reduced_motion else 1.0)
	_update_visibility()


func _update_visibility() -> void:
	_rect.visible = _enabled and _quality != "low"


func _ease_to(target: Dictionary, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_grade = target
		_push_grade(_grade)
		return
	var from := _grade.duplicate()
	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_tween.tween_method(_blend.bind(from, target), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _blend(t: float, from: Dictionary, to: Dictionary) -> void:
	var out := {}
	for k in to:
		var a: Variant = from.get(k, to[k])
		var b: Variant = to[k]
		if b is Color:
			out[k] = (a as Color).lerp(b as Color, t)
		else:
			out[k] = lerpf(float(a), float(b), t)
	_grade = out
	_push_grade(out)


func _push_grade(g: Dictionary) -> void:
	for k in g:
		_mat.set_shader_parameter(k, g[k])


func _process(delta: float) -> void:
	_time += delta
	_poll += delta
	if _poll >= SETTINGS_POLL:
		_poll = 0.0
		apply_settings()
	if not _rect.visible:
		return
	_flea = lerpf(_flea, _flea_target, 1.0 - exp(-delta * 3.0))
	_mat.set_shader_parameter("flea", _flea)
	if _reduced_motion:
		_mat.set_shader_parameter("flea_time", 0.0)
		_mat.set_shader_parameter("grain_seed", 0.0)
	else:
		_mat.set_shader_parameter("flea_time", _time)
		_mat.set_shader_parameter("grain_seed", floorf(_time * GRAIN_FPS))
