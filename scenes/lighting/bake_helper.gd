class_name BakeHelper
extends RefCounted
## Sets a room or wing up for baked lighting (S-01; ART_BIBLE 4: "baked/probe lighting for interiors"). Baking itself needs the Godot
## EDITOR (LightmapGI.bake is editor-only, and agent sandboxes render in software), so this helper does everything that can be done in
## code and leaves the human exactly one click: select the LightmapGI node, press "Bake Lightmaps" (docs/LIGHTING.md "Baking workflow").
##     var probes := BakeHelper.add_room_probes(room_root, AABB(Vector3(-3, 0, -2.5), Vector3(6, 3, 5)), "dining_room")
##     BakeHelper.ensure_uv2(room_root)          # primitive/greybox meshes need UV2 or they cannot be lightmapped
##     BakeHelper.mark_dynamic(chandelier_node)  # things that move (or go wrong) must not be baked into the lightmap
## Property writes are guarded (`_set_if`), so an engine-version difference warns instead of crashing.

## Team defaults for interiors (docs/LIGHTING.md). Quality ladder for the bake only; runtime quality is EnvPresets.for_quality.
const LIGHTMAP := {
	"bounces": 3,
	"directional": false,       # directional lightmaps cost 2x memory; turn on only for hero rooms with normal-mapped walls
	"interior": true,           # no sky contribution: interiors are dark unless a motivated light says otherwise
	"use_denoiser": true,
	"max_texture_size": 4096,
}


## Adds a LightmapGI and an interior ReflectionProbe covering `bounds` (in `parent`'s local space). Returns
## {"lightmap": LightmapGI, "reflection": ReflectionProbe}. Names are `<room_id>_lightmap` / `<room_id>_reflection`.
static func add_room_probes(parent: Node3D, bounds: AABB, room_id: String) -> Dictionary:
	var gi := LightmapGI.new()
	gi.name = room_id + "_lightmap"
	_set_if(gi, "quality", LightmapGI.BAKE_QUALITY_MEDIUM)
	_set_if(gi, "bounces", LIGHTMAP["bounces"])
	_set_if(gi, "directional", LIGHTMAP["directional"])
	_set_if(gi, "interior", LIGHTMAP["interior"])
	_set_if(gi, "use_denoiser", LIGHTMAP["use_denoiser"])
	_set_if(gi, "max_texture_size", LIGHTMAP["max_texture_size"])
	_set_if(gi, "environment_mode", LightmapGI.ENVIRONMENT_MODE_DISABLED)
	parent.add_child(gi)
	gi.position = bounds.get_center()
	var rp := ReflectionProbe.new()
	rp.name = room_id + "_reflection"
	rp.size = bounds.size
	rp.origin_offset = Vector3.ZERO
	_set_if(rp, "interior", true)
	_set_if(rp, "box_projection", true)
	_set_if(rp, "update_mode", ReflectionProbe.UPDATE_ONCE)
	_set_if(rp, "enable_shadows", false)
	_set_if(rp, "max_distance", maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) * 1.2)
	_set_if(rp, "intensity", 1.0)
	parent.add_child(rp)
	rp.position = bounds.get_center()
	return {"lightmap": gi, "reflection": rp}


## Gives every primitive mesh under `root` a UV2 channel (required by the lightmapper). Imported .glb meshes should be imported with
## "Light Baking: Static Lightmaps" instead (docs/LIGHTING.md). Returns how many meshes were changed.
static func ensure_uv2(root: Node) -> int:
	var n := 0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var pm := (node as MeshInstance3D).mesh as PrimitiveMesh
		if pm != null and not pm.add_uv2:
			pm.add_uv2 = true
			n += 1
	return n


## Everything under `node` is excluded from baking and lit dynamically (movable props, wrongness objects, the player's carried items).
static func mark_dynamic(node: Node) -> void:
	for g in _geometry(node):
		g.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC


## Everything under `node` is baked into the lightmap (walls, floors, ceilings, fixed furniture). This is the engine default; use it
## to undo mark_dynamic or to be explicit in a room builder.
static func mark_static(node: Node) -> void:
	for g in _geometry(node):
		g.gi_mode = GeometryInstance3D.GI_MODE_STATIC


## Lights that should be BAKED (static fixtures: chandeliers, wall sconces, window sun) get bake_mode static; lights that flicker or go
## wrong (lamp, candle, TV, anything with Unreality behaviour) stay dynamic so they can change at runtime.
static func set_light_baked(light: Light3D, baked: bool) -> void:
	light.light_bake_mode = Light3D.BAKE_STATIC if baked else Light3D.BAKE_DYNAMIC


static func _geometry(node: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if node is GeometryInstance3D:
		out.append(node)
	for n in node.find_children("*", "GeometryInstance3D", true, false):
		out.append(n)
	return out


static func _set_if(obj: Object, prop: String, value: Variant) -> void:
	if prop in obj:
		obj.set(prop, value)
	else:
		push_warning("BakeHelper: %s has no property '%s' in this engine version" % [obj.get_class(), prop])
