shader_type spatial;
// EXAMPLE for material authors (docs/ART_BIBLE.md "Materials"): a surface that is ordinary at unreality 0 and rots / swims as it rises.
// Copy this pattern: read the two global uniforms, scale every effect by a smoothstep of `unreality`, and keep it SUBTLE.
global uniform float unreality;
global uniform float unreal_time;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 wrong_tint : source_color = vec3(0.55, 0.62, 0.45);   // the colour this surface sickens toward
uniform float swim_amount = 0.012;                                  // how far the texture drifts at full unreality

void fragment() {
	float k = smoothstep(0.3, 1.0, unreality);
	vec2 uv = UV + vec2(sin(UV.y * 11.0 + unreal_time * 0.5), cos(UV.x * 9.0 + unreal_time * 0.4)) * swim_amount * k;
	vec3 c = texture(albedo_tex, uv).rgb;
	c = mix(c, c * wrong_tint * 1.4, k * 0.45);
	ALBEDO = c;
	ROUGHNESS = mix(0.85, 0.35, k * 0.5);   // things get wetter as they go wrong
}
