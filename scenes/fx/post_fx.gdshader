shader_type canvas_item;
// Full-screen post pass. Order: lens warp/wobble -> chroma split -> ghost (double vision) -> bloom approx -> grade -> hue drift
// -> sickly cast -> vignette -> grain -> fleas (edge specks). Drawn by the PostFX autoload on a CanvasLayer BELOW the UI.
// Every "unreality" uniform is driven by UnrealGrade.compose(); at level 0 the pass is a gentle film grade.
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// ---- grade ----
uniform vec3 tint : source_color = vec3(1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shadow_tint : source_color = vec3(0.5);
uniform vec3 highlight_tint : source_color = vec3(0.5);
uniform float split_amount : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 2.5) = 1.0;
uniform float contrast : hint_range(0.5, 1.5) = 1.0;
uniform float exposure : hint_range(-1.0, 1.0) = 0.0;

// ---- vignette ----
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_radius : hint_range(0.2, 1.2) = 0.78;
uniform float vignette_softness : hint_range(0.05, 1.0) = 0.55;
uniform vec3 vignette_color : source_color = vec3(0.02, 0.01, 0.04);

// ---- film grain ----
uniform float grain_amount : hint_range(0.0, 0.2) = 0.035;
uniform float grain_seed = 0.0;

// ---- chromatic aberration (chroma_amount is 0 under Reduced Motion; chroma_mult grows with unreality) ----
uniform float chroma_amount : hint_range(0.0, 0.01) = 0.0012;
uniform float chroma_mult : hint_range(0.0, 8.0) = 1.0;

// ---- bloom approximation ----
uniform float bloom_amount : hint_range(0.0, 1.0) = 0.12;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.72;

// ---- unreality ----
uniform float unreal : hint_range(0.0, 1.0) = 0.0;
uniform float unreal_time = 0.0;                           // slow time; frozen under Reduced Motion
uniform float warp : hint_range(0.0, 0.2) = 0.0;           // barrel lens
uniform float wobble : hint_range(0.0, 0.05) = 0.0;        // liquid sway (0 under Reduced Motion)
uniform float ghost : hint_range(0.0, 1.0) = 0.0;          // double vision
uniform float hue_shift = 0.0;                             // radians
uniform float sick : hint_range(0.0, 0.5) = 0.0;           // bilious cast
uniform vec3 sick_color : source_color = vec3(0.62, 0.80, 0.50);
uniform float specks : hint_range(0.0, 1.0) = 0.0;         // the fleas (0 under Reduced Motion)

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 hue_rotate(vec3 c, float a) {
	vec3 k = vec3(0.57735);
	float cs = cos(a);
	float sn = sin(a);
	return c * cs + cross(k, c) * sn + k * dot(k, c) * (1.0 - cs);
}

// Tiny dark specks that crawl slowly near the screen edge. Slow (well under 3 Hz), small, never a flash.
float flea_specks(vec2 uv, float aspect, float t, float density, float edge) {
	vec2 g = uv * vec2(aspect, 1.0) * 46.0;
	g += vec2(sin(t * 0.21 + g.y * 0.07), t * 0.18);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash21(id);
	if (h > density * edge * 0.22) {
		return 0.0;
	}
	vec2 off = (vec2(hash21(id + 7.1), hash21(id + 3.3)) - 0.5) * 0.5;
	float d = length(f - off);
	float size = 0.10 + 0.08 * hash21(id + 1.7);
	return smoothstep(size, size * 0.4, d);
}

void fragment() {
	vec2 uv0 = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 c0 = uv0 - 0.5;
	vec2 ca = c0 * vec2(aspect, 1.0);
	float r = length(ca) / (0.5 * length(vec2(aspect, 1.0)));   // 0 centre .. 1 corner

	// lens warp + liquid wobble
	vec2 wc = c0 * (1.0 + warp * dot(ca, ca) * 4.0);
	wc += vec2(sin(uv0.y * 9.0 + unreal_time * 0.8), cos(uv0.x * 7.0 + unreal_time * 0.6)) * wobble;
	vec2 uv = wc + 0.5;
	vec2 c = wc;

	// chromatic aberration: split R/B radially, stronger toward the edges
	vec2 shift = c * chroma_amount * chroma_mult * (0.3 + r * 1.4);
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	// double vision: a second, drifting copy of the world
	if (ghost > 0.0) {
		vec2 go = vec2(sin(unreal_time * 0.55), cos(unreal_time * 0.41)) * 0.006 * ghost + vec2(0.004, 0.0) * ghost;
		col = mix(col, texture(screen_tex, uv + go).rgb, ghost * 0.38);
	}

	// bloom approx
	if (bloom_amount > 0.0) {
		vec3 bl = vec3(0.0);
		for (int i = 0; i < 3; i++) {
			float lod = 3.0 + float(i) * 1.5;
			vec2 px = SCREEN_PIXEL_SIZE * exp2(lod);
			bl += max(textureLod(screen_tex, uv, lod).rgb - vec3(bloom_threshold), vec3(0.0));
			bl += max(textureLod(screen_tex, uv + vec2(px.x, 0.0), lod).rgb - vec3(bloom_threshold), vec3(0.0));
			bl += max(textureLod(screen_tex, uv - vec2(px.x, 0.0), lod).rgb - vec3(bloom_threshold), vec3(0.0));
			bl += max(textureLod(screen_tex, uv + vec2(0.0, px.y), lod).rgb - vec3(bloom_threshold), vec3(0.0));
			bl += max(textureLod(screen_tex, uv - vec2(0.0, px.y), lod).rgb - vec3(bloom_threshold), vec3(0.0));
		}
		col += bl * (bloom_amount / 15.0) * 2.2;
	}

	// grade
	col *= exp2(exposure);
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col = mix(col, col * tint, tint_amount);
	vec3 split = mix(shadow_tint * 2.0, highlight_tint * 2.0, smoothstep(0.15, 0.85, luma));
	col = mix(col, col * split, split_amount);

	// unreality colour: hue drift and a faint bilious cast
	if (hue_shift != 0.0) {
		col = hue_rotate(col, hue_shift);
	}
	col = mix(col, col * sick_color * 1.35, sick);

	// vignette, breathing very slowly with unreality
	float breathe = 1.0 + unreal * 0.25 * sin(unreal_time * 1.1) * step(0.0001, wobble + specks);
	float vig = smoothstep(vignette_radius, vignette_radius + vignette_softness, r) * vignette_strength * breathe;
	col = mix(col, vignette_color, clamp(vig, 0.0, 1.0));

	// grain
	float g = hash21(uv0 * vec2(1280.0, 720.0) + vec2(grain_seed * 17.0, grain_seed * 31.0)) - 0.5;
	col += g * grain_amount;

	// the fleas: dark specks crawling in from the edges
	if (specks > 0.001) {
		float edge = smoothstep(0.45, 1.0, r);
		float s = flea_specks(uv0, aspect, unreal_time, specks, edge);
		col = mix(col, vec3(0.03, 0.0, 0.0), clamp(s * 0.85, 0.0, 0.9));
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
