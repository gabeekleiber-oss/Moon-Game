extends Node
## Standalone demo (F6): plays data/dialogue/_sample.json on a loop. Click / E / Space advance, 1-3 choose.

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = -1
	layer.add_child(bg)
	add_child(layer)
	while is_inside_tree():
		await Dialogue.play("_sample")
		await get_tree().create_timer(1.0).timeout
