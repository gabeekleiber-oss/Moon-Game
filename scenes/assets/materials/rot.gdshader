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
uniform vec3 rot_tint : source_color = vec3(0.48, 0.56, 0.38);
uniform float rot_strength = 0.62;
void vertex() {
	if (has_height) {
		VERTEX += NORMAL * ((texture(height_tex, UV).r - 0.5) * height_scale);
	}
}
void fragment() {
	float wrong = smoothstep(0.18, 0.96, unreality);
	vec3 base = base_color.rgb;
	if (has_albedo) {
		base *= texture(albedo_tex, UV).rgb;
	}
	float mottling = 0.92 + 0.08 * sin(UV.x * 31.0 + sin(UV.y * 19.0 + unreal_time * 0.03));
	ALBEDO = mix(base, base * rot_tint * mottling, wrong * rot_strength);
	float rough = roughness_base;
	if (has_roughness) {
		rough *= texture(roughness_tex, UV).r;
	}
	ROUGHNESS = mix(clamp(rough, 0.05, 1.0), 0.58, wrong);
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
	AO = 1.0;
	if (has_ao) {
		AO = texture(ao_tex, UV).r;
	}
	METALLIC = metallic_base;
}
