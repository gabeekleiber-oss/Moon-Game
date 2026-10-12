class_name LightBudget
extends RefCounted
## Counts lights against the written budget (docs/ART_BIBLE.md 4, docs/LIGHTING.md). Pure helpers; S-12's perf scenes and every act's
## test can call them:
##     var r := LightBudget.in_view(camera, act_root)   # {"total", "shadow", "shadow_nodes", "over"}
##     assert(r["over"] == false, LightBudget.describe(r))
## Budget: at most MAX_SHADOW_IN_VIEW shadow-casting dynamic lights in view (a DirectionalLight3D with shadows counts, always in view);
## at most MAX_LIGHTS_IN_VIEW lights of any kind (a team budget, see docs/LIGHTING.md; the engine limit is far higher).

const MAX_SHADOW_IN_VIEW := 2
const MAX_LIGHTS_IN_VIEW := 24


## Every visible Light3D under `root`, whether or not the camera can see it.
static func count(root: Node) -> Dictionary:
	return _tally(_lights(root), null)


## Lights that matter for what `camera` sees: directional lights always; omni/spot when their range sphere touches the view frustum.
static func in_view(camera: Camera3D, root: Node) -> Dictionary:
	return _tally(_lights(root), camera)


## One line for assert messages and logs.
static func describe(r: Dictionary) -> String:
	var names: PackedStringArray = PackedStringArray()
	for n in r["shadow_nodes"]:
		names.append(String((n as Node).name))
	return "lights %d/%d, shadow casters %d/%d (%s)" % [r["total"], MAX_LIGHTS_IN_VIEW, r["shadow"], MAX_SHADOW_IN_VIEW, ", ".join(names)]


static func _lights(root: Node) -> Array[Light3D]:
	var out: Array[Light3D] = []
	if root is Light3D and (root as Light3D).is_visible_in_tree():
		out.append(root)
	for n in root.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		if l.is_visible_in_tree():
			out.append(l)
	return out


static func _tally(lights: Array[Light3D], camera: Camera3D) -> Dictionary:
	var planes: Array[Plane] = []
	if camera != null:
		planes = camera.get_frustum()
	var total := 0
	var shadow := 0
	var nodes: Array[Light3D] = []
	for l in lights:
		if camera != null and not _touches(l, planes):
			continue
		total += 1
		if l.shadow_enabled:
			shadow += 1
			nodes.append(l)
	return {"total": total, "shadow": shadow, "shadow_nodes": nodes,
		"over": shadow > MAX_SHADOW_IN_VIEW or total > MAX_LIGHTS_IN_VIEW}


static func _touches(l: Light3D, planes: Array[Plane]) -> bool:
	var r := 0.0
	if l is OmniLight3D:
		r = (l as OmniLight3D).omni_range
	elif l is SpotLight3D:
		r = (l as SpotLight3D).spot_range
	else:
		return true   # directional: affects the whole view
	var p := l.global_position
	for pl in planes:
		if pl.distance_to(p) > r:
			return false   # the whole range sphere is on the outside of this frustum plane
	return true
