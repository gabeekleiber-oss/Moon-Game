shader_type spatial;
// Milky procedural moon: 3D cellular craters, soft maria, and a dark socket around the eye.
// Object-space based, so it needs no textures. Used by the moon sphere and (tinted) by the lids.

uniform vec3 milk : source_color = vec3(0.90, 0.91, 0.88);
uniform vec3 shade : source_color = vec3(0.50, 0.55, 0.64);
uniform float crater_scale = 5.0;
uniform float crater_depth = 0.55;
uniform float glow = 0.22;
uniform vec3 eye_dir = vec3(0.0, 0.0, 1.0);
uniform float socket_radius = 0.42;   // radians of arc around eye_dir that is darkened
uniform float socket_soft = 0.18;

varying vec3 opos;

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}

// returns x = crater bowl/rim profile in [-1,1], y = distance to nearest centre
vec2 craters(vec3 p, float scale) {
	vec3 q = p * scale;
	vec3 i = floor(q);
	vec3 f = fract(q);
	float best = 9.0;
	float prof = 0.0;
	for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++) for (int z = -1; z <= 1; z++) {
		vec3 g = vec3(float(x), float(y), float(z));
		vec3 o = hash3(i + g);
		vec3 r = g + o - f;
		float d = length(r);
		float rad = 0.28 + 0.22 * o.x;
		float t = d / rad;
		float bowl = -smoothstep(1.0, 0.0, t) * (1.0 - t * 0.3);
		float rim = smoothstep(0.75, 1.0, t) * smoothstep(1.35, 1.0, t) * 0.6;
		float v = (o.y > 0.35) ? bowl + rim : 0.0;
		if (abs(v) > abs(prof)) prof = v;
		best = min(best, d);
	}
	return vec2(prof, best);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = mix(mix(mix(hash3(i).x, hash3(i + vec3(1,0,0)).x, f.x), mix(hash3(i + vec3(0,1,0)).x, hash3(i + vec3(1,1,0)).x, f.x), f.y),
		mix(mix(hash3(i + vec3(0,0,1)).x, hash3(i + vec3(1,0,1)).x, f.x), mix(hash3(i + vec3(0,1,1)).x, hash3(i + vec3(1,1,1)).x, f.x), f.y), f.z);
	return n;
}

void vertex() {
	opos = VERTEX;
}

void fragment() {
	vec3 p = normalize(opos);
	vec2 c1 = craters(p, crater_scale);
	vec2 c2 = craters(p + 3.7, crater_scale * 2.3);
	float prof = c1.x + 0.45 * c2.x;
	float maria = vnoise(p * 2.2) * 0.6 + vnoise(p * 6.0) * 0.4;
	float k = clamp(0.62 + prof * crater_depth - (maria - 0.5) * 0.35, 0.0, 1.0);
	vec3 col = mix(shade, milk, k);
	float ang = acos(clamp(dot(p, normalize(eye_dir)), -1.0, 1.0));
	float sock = 1.0 - smoothstep(socket_radius - socket_soft, socket_radius + socket_soft, ang);
	col = mix(col, shade * 0.18, sock * 0.9);
	ALBEDO = col;
	ROUGHNESS = 0.95;
	EMISSION = col * glow;
}
