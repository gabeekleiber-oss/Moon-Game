class_name UiFonts
extends RefCounted
## Typeset fonts (assets/fonts, OFL). Each getter returns null if the file is missing, so callers keep the engine default.

const DIR := "res://assets/fonts/typeset_fonts_serif_typewriter_handwriti/"
const SERIF := DIR + "ebgaramond/EBGaramond[wght].ttf"
const TYPEWRITER := DIR + "courierprime/CourierPrime-Regular.ttf"
const HANDWRITING := DIR + "reeniebeanie/ReenieBeanie.ttf"

static var _cache: Dictionary = {}


static func get_font(path: String) -> Font:
	if not _cache.has(path):
		_cache[path] = load(path) as Font if ResourceLoader.exists(path) else null
	return _cache[path]


## Applies the font to a Control's theme `font` override; no-op when the font is missing.
static func apply(control: Control, path: String) -> void:
	var f := get_font(path)
	if f != null:
		control.add_theme_font_override("font", f)
