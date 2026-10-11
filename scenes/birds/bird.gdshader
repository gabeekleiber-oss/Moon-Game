shader_type spatial;
render_mode cull_disabled;
// F-11: bird surface. Vertex colour RGB = species colour; vertex colour A = wing weight (0 body .. 1 wing tip), used to flap.
// INSTANCE_CUSTOM.x (MultiMesh custom data) = per-bird flap phase offset; INSTANCE_CUSTOM.y = glide 0..1 (0 = full flap, 1 = wings still).
uniform float flap_speed = 16.0;
uniform float flap_amount = 0.075;
uniform float phase = 0.0;
uniform float flap_strength = 1.0;

void vertex() {
	float w = COLOR.a;
	float s = flap_strength * (1.0 - clamp(INSTANCE_CUSTOM.y, 0.0, 1.0));
	VERTEX.y += w * sin(TIME * flap_speed + phase + INSTANCE_CUSTOM.x) * flap_amount * s;
}

void fragment() {
	// palette colours are authored in sRGB; vertex colours arrive as-is, so convert to linear
	vec3 c = COLOR.rgb;
	ALBEDO = mix(pow((c + vec3(0.055)) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
	ROUGHNESS = 0.85;
}
