class_name InteractionHud
extends CanvasLayer
## Reticle dot + "[E] prompt" label, built in code. (F-02)
##
## Created by InteractionRay. Listens to Events.interact_focus_changed; no other setup.
## F-03 (HUD) may restyle or replace it, but should keep reacting to the same signal.

const RETICLE_SIZE := 6.0
const RETICLE_FOCUS_SIZE := 12.0

var _reticle: Panel
var _style: StyleBoxFlat
var _label: Label


func _init() -> void:
	layer = 10
	name = "InteractionHud"


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_style = StyleBoxFlat.new()
	_style.bg_color = Color(1, 1, 1, 0.7)
	_style.set_corner_radius_all(16)
	_reticle = Panel.new()
	_reticle.add_theme_stylebox_override("panel", _style)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.set_anchors_preset(Control.PRESET_CENTER)
	root.add_child(_reticle)
	_set_reticle_size(RETICLE_SIZE)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.offset_left = -300.0
	_label.offset_right = 300.0
	_label.offset_top = 24.0
	_label.offset_bottom = 56.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.15, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	root.add_child(_label)

	Events.interact_focus_changed.connect(_on_focus_changed)


func _on_focus_changed(target: Node3D) -> void:
	if target == null:
		_label.visible = false
		_set_reticle_size(RETICLE_SIZE)
		_style.bg_color = Color(1, 1, 1, 0.7)
		return
	_label.text = "[E] %s" % str(target.get("prompt"))
	_label.visible = true
	_set_reticle_size(RETICLE_FOCUS_SIZE)
	_style.bg_color = Color(1, 0.86, 0.42, 0.95)


func _set_reticle_size(s: float) -> void:
	_reticle.offset_left = -s * 0.5
	_reticle.offset_top = -s * 0.5
	_reticle.offset_right = s * 0.5
	_reticle.offset_bottom = s * 0.5
