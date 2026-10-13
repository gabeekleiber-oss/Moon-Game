shader_type spatial;
global uniform float unreality;
global uniform float unreal_time;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 damp_tint : source_color = vec3(0.48, 0.54, 0.46);
uniform float wetness = 0.72;
void fragment() {
	float wrong = smoothstep(0.28, 0.82, unreality);
	vec3 base = texture(albedo_tex, UV).rgb;
	ALBEDO = mix(base, base * damp_tint, wrong * 0.52);
	ROUGHNESS = mix(0.82, 0.12, clamp(wetness + wrong * 0.18, 0.0, 1.0));
	METALLIC = 0.0;
}
