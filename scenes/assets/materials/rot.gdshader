shader_type spatial;
global uniform float unreality;
global uniform float unreal_time;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 rot_tint : source_color = vec3(0.48, 0.56, 0.38);
uniform float rot_strength = 0.62;
void fragment() {
	float wrong = smoothstep(0.18, 0.96, unreality);
	vec3 base = texture(albedo_tex, UV).rgb;
	float mottling = 0.92 + 0.08 * sin(UV.x * 31.0 + sin(UV.y * 19.0 + unreal_time * 0.03));
	ALBEDO = mix(base, base * rot_tint * mottling, wrong * rot_strength);
	ROUGHNESS = mix(0.86, 0.58, wrong);
}
