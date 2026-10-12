class_name MoodEnvironment
extends WorldEnvironment
## The WorldEnvironment every location scene should carry (S-01). It owns one `Environment`, shows a named look from EnvPresets
## (night_dark, dawn, dream, day, fire) and keeps it in step with the game:
##  * `set_look(name, seconds)` eases to another look (acts do this when the story moves on);
##  * `follow_grade = true` makes it track the location mood the act already sets for PostFX (`ActBase.base_grade`), so an act needs
##    no extra code: drop a MoodEnvironment in the scene and tick the box;
##  * the hidden Unreality value thickens/sickens the air (EnvPresetsScript.with_unreality);
##  * `Game.settings["quality"]` ("auto"/"high"/"medium"/"low") steps the expensive passes down (EnvPresetsScript.for_quality).
## Nothing here moves fast or flashes, so Reduced Motion needs no alternative; eases are slow fades of fog and colour.
## Runs standalone (F6) in any scene that has the autoloads. A scene should have exactly one.
##     var m := MoodEnvironment.new(); m.look = "dawn"; add_child(m)
##     m.set_look("fire", 2.0)

## The look shown at start (a name from EnvPresetsScript.names()).
@export var look: String = "night_dark"
## When true, follow PostFX's current base-grade name (UnrealGrade) through EnvPresetsScript.for_grade.
@export var follow_grade: bool = false

const EnvPresetsScript = preload("res://scenes/lighting/env_presets.gd")
const EPSILON_LEVEL := 0.002

var _from: Dictionary = {}
var _to: Dictionary = {}
var _cur: Dictionary = {}
var _t: float = 1.0
var _dur: float = 0.0
var _dirty: bool = true
var _last_level: float = -1.0
var _last_quality: String = ""
var _grade_seen: String = ""


func _ready() -> void:
	if environment == null:
		environment = Environment.new()
	if not EnvPresetsScript.names().has(look):
		look = "night_dark"
	_to = EnvPresetsScript.get_preset(look)
	_from = _to
	_cur = _to
	_refresh()


## Eases to a named look over `seconds` (0 = instantly). Unknown names are ignored with a warning.
func set_look(look_name: String, seconds: float = 1.5) -> void:
	if not EnvPresetsScript.names().has(look_name):
		push_warning("MoodEnvironment: unknown look '%s'" % look_name)
		return
	look = look_name
	_from = _cur
	_to = EnvPresetsScript.get_preset(look_name)
	if seconds <= 0.0:
		_cur = _to
		_t = 1.0
		_dur = 0.0
	else:
		_t = 0.0
		_dur = seconds
	_dirty = true


## The look currently being shown or eased to.
func get_look() -> String:
	return look


## The parameters last written to the Environment (after blend, quality and Unreality). For tests and the lighting budget.
func get_applied() -> Dictionary:
	return _applied


var _applied: Dictionary = {}


func _process(delta: float) -> void:
	if follow_grade:
		var g: String = PostFX.get_grade_name()
		if g != _grade_seen and g != "custom":
			_grade_seen = g
			set_look(EnvPresetsScript.for_grade(g), 1.5)
	if _t < 1.0:
		_t = minf(1.0, _t + delta / maxf(_dur, 0.001))
		_cur = EnvPresetsScript.lerp_params(_from, _to, _t)
		_dirty = true
	var level: float = Unreality.level
	var quality: String = str(Game.settings.get("quality", "auto"))
	if _dirty or absf(level - _last_level) > EPSILON_LEVEL or quality != _last_quality:
		_refresh()


func _refresh() -> void:
	_last_level = Unreality.level
	_last_quality = str(Game.settings.get("quality", "auto"))
	_dirty = false
	var p: Dictionary = EnvPresetsScript.with_unreality(EnvPresetsScript.for_quality(_cur, _last_quality), _last_level)
	_applied = p
	EnvPresetsScript.apply(environment, p)
