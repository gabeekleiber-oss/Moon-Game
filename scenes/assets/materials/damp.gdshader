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
uniform vec3 damp_tint : source_color = vec3(0.48, 0.54, 0.46);
uniform float wetness = 0.72;
void fragment() {
	float wrong = smoothstep(0.28, 0.82, unreality);
	vec3 base = base_color.rgb;
	if (has_albedo) {
		base *= texture(albedo_tex, UV).rgb;
	}
	ALBEDO = mix(base, base * damp_tint, wrong * 0.52);
\tfloat rough = roughness_base;\n\tif (has_roughness) {\n\t\trough *= texture(roughness_tex, UV).r;\n\t}\n\tROUGHNESS = mix(clamp(rough, 0.05, 1.0), 0.12, clamp(wetness + wrong * 0.18, 0.0, 1.0));\n\tif (has_normal) {\n\t\tNORMAL_MAP = texture(normal_tex, UV).rgb;\n\t\tNORMAL_MAP_DEPTH = normal_scale;\n\t}\n\tAO = 1.0;\n\tif (has_ao) {\n\t\tAO = texture(ao_tex, UV).r;\n\t}\n\tMETALLIC = metallic_base;\n}\n