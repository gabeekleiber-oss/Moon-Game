extends Node
## Dev tool: renders the sandbox with the PostFX shader under given uniform presets and saves PNGs.
## godot --path . --rendering-method gl_compatibility res://tests/_post_shot.tscn -- --preset=name --out=/tmp/x.png
const SHADER := preload("res://scenes/fx/post_fx.gdshader")

func _ready() -> void:
	var out := "/tmp/shots/post.png"
	var params := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
		elif a.begins_with("--p="):   # --p=name:value (colours as r,g,b)
			var kv := a.substr(4).split(":")
			var v := kv[1]
			params[kv[0]] = Color(float(v.split(",")[0]), float(v.split(",")[1]), float(v.split(",")[2])) if v.contains(",") else float(v)
	add_child((load("res://scenes/levels/sandbox.tscn") as PackedScene).instantiate())
	var layer := CanvasLayer.new()
	layer.layer = 5
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	for k in params:
		mat.set_shader_parameter(k, params[k])
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	get_tree().quit()
