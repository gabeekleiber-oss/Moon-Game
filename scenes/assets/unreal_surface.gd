class_name UnrealSurface
extends RefCounted
## Builds one of the shared Unreality surface shaders over an existing StandardMaterial3D.
## PBR maps and base values are transferred so the effect does not discard the material library.

const SHADERS := {
	"damp": "res://scenes/assets/materials/damp.gdshader",
	"rot": "res://scenes/assets/materials/rot.gdshader",
	"swim": "res://scenes/assets/materials/swim.gdshader",
	"crawl": "res://scenes/assets/materials/crawl.gdshader",
}

static func make(kind: String, base: Material) -> Material:
	if not SHADERS.has(kind):
		push_warning("UnrealSurface: unknown surface effect '%s'" % kind)
		return base
	var source := base as StandardMaterial3D
	if source == null:
		push_warning("UnrealSurface: effects require a StandardMaterial3D base")
		return base
	var shader_resource: Resource = load(SHADERS[kind])
	if not shader_resource is Shader:
		push_warning("UnrealSurface: could not load shader for " + kind)
		return base
	var out := ShaderMaterial.new()
	out.resource_name = "UnrealSurface_" + kind
	out.shader = shader_resource
	out.set_shader_parameter("base_color", source.albedo_color)
	out.set_shader_parameter("roughness_base", source.roughness)
	out.set_shader_parameter("metallic_base", source.metallic)
	out.set_shader_parameter("normal_scale", source.normal_scale)
	out.set_shader_parameter("height_scale", source.heightmap_scale if source.heightmap_enabled else 0.0)
	var albedo := source.albedo_texture
	var normal := source.normal_texture if source.normal_enabled else null
	var roughness := source.roughness_texture
	var ao := source.ao_texture if source.ao_enabled else null
	var height := source.heightmap_texture if source.heightmap_enabled else null
	out.set_shader_parameter("has_albedo", albedo != null)
	out.set_shader_parameter("has_normal", normal != null)
	out.set_shader_parameter("has_roughness", roughness != null)
	out.set_shader_parameter("has_ao", ao != null)
	out.set_shader_parameter("has_height", height != null)
	if albedo: out.set_shader_parameter("albedo_tex", albedo)
	if normal: out.set_shader_parameter("normal_tex", normal)
	if roughness: out.set_shader_parameter("roughness_tex", roughness)
	if ao: out.set_shader_parameter("ao_tex", ao)
	if height: out.set_shader_parameter("height_tex", height)
	return out
