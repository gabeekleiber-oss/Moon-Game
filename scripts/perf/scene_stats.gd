class_name SceneStats
extends RefCounted
## Counts what makes a scene expensive (S-12): lights, shadow casters, mesh surfaces (a draw-call estimate), particles.
## Pure node-tree maths, so it works headless. Use `collect(root)` then `violations(stats, limits)`.

## Scene-wide limits (the per-VIEW light limits live in LightBudget). Proposed by S-12; the human confirms them.
const LIMITS := {
	"lights": 64,          ## all Light3D in the scene (not in view)
	"shadow_lights": 6,    ## shadow-casting lights in the whole scene (only 2 may be in view at once)
	"surfaces": 2500,      ## mesh surfaces ~ draw calls before culling/instancing
	"particles": 20000,    ## sum of particle amounts
}

## Returns {nodes, lights, shadow_lights, meshes, surfaces, particles}.
static func collect(root: Node) -> Dictionary:
	var s := {"nodes": 0, "lights": 0, "shadow_lights": 0, "meshes": 0, "surfaces": 0, "particles": 0}
	_walk(root, s)
	return s

static func _walk(n: Node, s: Dictionary) -> void:
	s["nodes"] += 1
	if n is Light3D:
		s["lights"] += 1
		if (n as Light3D).shadow_enabled:
			s["shadow_lights"] += 1
	elif n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.visible and mi.mesh != null:
			s["meshes"] += 1
			s["surfaces"] += maxi(mi.mesh.get_surface_count(), 1)
	elif n is GPUParticles3D:
		s["particles"] += (n as GPUParticles3D).amount
	elif n is CPUParticles3D:
		s["particles"] += (n as CPUParticles3D).amount
	for c in n.get_children():
		_walk(c, s)

## Human-readable list of every limit the stats exceed (empty = within budget).
static func violations(stats: Dictionary, limits: Dictionary = LIMITS) -> Array[String]:
	var out: Array[String] = []
	for k in limits:
		if stats.has(k) and int(stats[k]) > int(limits[k]):
			out.append("%s %d > %d" % [k, stats[k], limits[k]])
	return out

static func describe(stats: Dictionary) -> String:
	return "nodes=%d lights=%d (shadow %d) meshes=%d surfaces=%d particles=%d" % [
		stats["nodes"], stats["lights"], stats["shadow_lights"], stats["meshes"], stats["surfaces"], stats["particles"]]
