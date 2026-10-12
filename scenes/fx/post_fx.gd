extends Node
## Autoload `PostFX`: the full-screen post pass. The picture degrades as the hidden Unreality value rises (see UnrealGrade and
## docs/ART_BIBLE.md): colour drains then over-saturates, the lens warps and sways, double vision, hue drift, a bilious cast,
## the world closing in, and tiny "fleas" crawling at the screen edge. It draws a ColorRect with scenes/fx/post_fx.gdshader on a
## CanvasLayer BELOW the UI (layer 5; dialogue/menus are 10+), so only the 3D world is affected. It runs by itself:
##  - every frame it composes (base grade of the location) + (curves of Unreality.level) and pushes shader uniforms
##  - Game.settings: `reduced_motion` kills chroma, wobble, specks, grain flicker and slow time; `quality` == "low" turns the pass off.
## From act scripts:
##     PostFX.set_base_grade("lake_dusk", 2.0)       # location mood (UnrealGradeScript.names()), eased over 2 s (ActBase does this for you)
##     PostFX.set_base_grade({"saturation": 0.4}, 1.0)   # or a partial dictionary on top of the current base
##     PostFX.set_param("vignette_strength", 0.8)    # one uniform, immediately (re-composed away next frame unless it is a base key)
##     PostFX.set_enabled(false)                     # e.g. for a title card
const UnrealGradeScript = preload("res://scenes/fx/unreal_grade.gd")
const SHADER := preload("res://scenes/fx/post_fx.gdshader")
const CHROMA_DEFAULT := 0.0012
const GRAIN_FPS := 12.0          # grain re-rolls 12x/s (fine film noise, not a flash; Reduced Motion freezes it)
const SETTINGS_POLL := 0.5

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _grade: Dictionary = UnrealGradeScript.NEUTRAL.duplicate()
var _grade_name: String = "neutral"
var _tween: Tween
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
	_push_grade(UnrealGradeScript.compose(_grade, 0.0))
	apply_settings()


## Eases the LOCATION mood to a named base grade (UnrealGradeScript.names()) or to a partial Dictionary of shader uniforms applied
## over the current base, over `duration` seconds (0 = instant). Unreality is layered on top automatically.
func set_base_grade(grade: Variant, duration: float = 1.5) -> void:
	if grade is String:
		_grade_name = grade
		_ease_to(UnrealGradeScript.get_base(grade), duration)
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
	var motion := 0.0 if _reduced_motion else 1.0
	_push_grade(UnrealGradeScript.compose(_grade, Unreality.level, motion))
	_mat.set_shader_parameter("unreal_time", 0.0 if _reduced_motion else _time)
	_mat.set_shader_parameter("grain_seed", 0.0 if _reduced_motion else floorf(_time * GRAIN_FPS))
