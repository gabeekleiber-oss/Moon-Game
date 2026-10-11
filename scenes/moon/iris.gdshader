shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
// Green-and-blue iris disc (CANON: the eye is green and blue). UV centre = disc centre.
// Dark pupil radius is driven by `pupil` (0..1 of the iris radius).

uniform vec3 green : source_color = vec3(0.20, 0.68, 0.38);
uniform vec3 blue : source_color = vec3(0.14, 0.38, 0.85);
uniform float pupil = 0.35;
uniform float light = 1.0;
uniform float iris_radius = 1.0;   // object-space radius of the iris on the eyeball surface

varying vec3 opos;

void vertex() {
	opos = VERTEX;
}

float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1,0)), f.x), mix(h(i + vec2(0,1)), h(i + vec2(1,1)), f.x), f.y);
}

void fragment() {
	if (opos.z <= 0.0) discard;
	vec2 q = opos.xy / iris_radius;
	float r = length(q);
	if (r > 1.0) discard;
	float a = atan(q.y, q.x);
	float fibre = vn(vec2(a * 6.0, r * 5.0)) * 0.6 + vn(vec2(a * 14.0, r * 9.0)) * 0.4;
	// blue toward the pupil, green toward the rim, mottled by fibres
	float mixv = clamp(smoothstep(0.2, 0.95, r) * 0.9 + (fibre - 0.5) * 0.7, 0.0, 1.0);
	vec3 col = mix(blue, green, mixv) * (0.65 + 0.7 * fibre);
	col *= 1.0 - smoothstep(0.82, 1.0, r) * 0.75;           // limbal ring
	float pr = max(pupil, 0.04);
	col = mix(vec3(0.0), col, smoothstep(pr - 0.03, pr + 0.03, r));
	ALBEDO = col * light;
}
