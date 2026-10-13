shader_type spatial;
global uniform float unreality;
global uniform float unreal_time;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D ao_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D height_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float roughness_base = 0.78;
uniform float metallic_base = 0.0;
uniform float normal_scale = 1.0;
uniform float height_scale = 0.0;
uniform bool has_albedo = false;
uniform bool has_normal = false;
uniform bool has_roughness = false;
uniform bool has_ao = false;
uniform bool has_height = false;
void vertex() {
	if (has_height) {
		VERTEX += NORMAL * ((texture(height_tex, UV).r - 0.5) * height_scale);
	}
}
uniform vec3 rot_tint : source_color = vec3(0.48, 0.56, 0.38);
uniform float rot_strength = 0.62;
void fragment() {
	float wrong = smoothstep(0.18, 0.96, unreality);
	vec2 uv = UV;
	vec3 base = base_color.rgb * (texture(albedo_tex, uv).rgb if has_albedo else vec3(1.0));
	float mottling = 0.92 + 0.08 * sin(UV.x * 31.0 + sin(UV.y * 19.0 + unreal_time * 0.03));
	ALBEDO = mix(base, base * rot_tint * mottling, wrong * rot_strength);
	float rough = roughness_base * (texture(roughness_tex, uv).r if has_roughness else 1.0);
	ROUGHNESS = mix(rough, 0.58, wrong);
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
	AO = texture(ao_tex, UV).r if has_ao else 1.0;
	METALLIC = metallic_base;
}
