shader_type spatial;
global uniform float unreality;
global uniform float unreal_time;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 crawl_tint : source_color = vec3(0.13, 0.10, 0.08);
uniform float crawl_amount = 0.18;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	float wrong = smoothstep(0.52, 0.98, unreality);
	vec2 cell = floor(UV * 34.0 + unreal_time * 0.08);
	float speck = step(0.91, hash(cell));
	vec3 base = texture(albedo_tex, UV).rgb;
	ALBEDO = mix(base, mix(base, crawl_tint, speck), wrong * crawl_amount);
	ROUGHNESS = 0.8;
}
