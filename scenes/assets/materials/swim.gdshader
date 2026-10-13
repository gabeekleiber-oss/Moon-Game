shader_type spatial;
global uniform float unreality;
global uniform float unreal_time;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float swim_amount = 0.012;
void fragment() {
	float wrong = smoothstep(0.32, 0.95, unreality);
	vec2 drift = vec2(sin(UV.y * 12.0 + unreal_time * 0.31), cos(UV.x * 10.0 + unreal_time * 0.27));
	vec2 uv = UV + drift * swim_amount * wrong;
	ALBEDO = texture(albedo_tex, uv).rgb;
	ROUGHNESS = 0.76;
}
