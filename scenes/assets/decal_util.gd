class_name DecalUtil
extends RefCounted
## Consistent low-cost helpers for wear and grime. Decal textures require license records.

static func create_albedo_decal(texture: Texture2D, decal_size: Vector3 = Vector3(1.0, 1.0, 0.15), fade: float = 0.2) -> Decal:
	var decal := Decal.new()
	decal.size = Vector3(maxf(decal_size.x, 0.01), maxf(decal_size.y, 0.01), maxf(decal_size.z, 0.01))
	decal.texture_albedo = texture
	decal.upper_fade = clampf(fade, 0.0, 1.0)
	decal.lower_fade = clampf(fade, 0.0, 1.0)
	decal.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return decal

static func create_grime_decal(texture: Texture2D, size: Vector3 = Vector3(0.8, 0.8, 0.12), opacity: float = 0.35) -> Decal:
	var decal := create_albedo_decal(texture, size)
	decal.modulate = Color(1.0, 1.0, 1.0, clampf(opacity, 0.0, 1.0))
	return decal
