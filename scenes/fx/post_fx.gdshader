shader_type canvas_item;
// Full-screen post pass (F-04): chroma -> bloom approx -> grade -> vignette -> grain -> flea overlay.
// Drawn by the PostFX autoload on a CanvasLayer BELOW the HUD, so UI is never graded.
// Grading is deliberately gentle: DESIGN.md says "grade via light + fog tint, never a flat filter".
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// ---- grade ----
uniform vec3 tint : source_color = vec3(1.0);              // multiplied in by tint_amount
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shadow_tint : source_color = vec3(0.5);       // split-toning colours (0.5 grey = neutral)
uniform vec3 highlight_tint : source_color = vec3(0.5);
uniform float split_amount : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 1.5) = 1.0;
uniform float exposure : hint_range(-1.0, 1.0) = 0.0;      // in stops

// ---- vignette ----
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_radius : hint_range(0.2, 1.2) = 0.78;
uniform float vignette_softness : hint_range(0.05, 1.0) = 0.55;
uniform vec3 vignette_color : source_color = vec3(0.02, 0.01, 0.04);

// ---- film grain ----
uniform float grain_amount : hint_range(0.0, 0.2) = 0.035;
uniform float grain_seed = 0.0;                            // script steps this ~12x/s (frozen under Reduced Motion)

// ---- chromatic aberration (0 under Reduced Motion) ----
uniform float chroma_amount : hint_range(0.0, 0.01) = 0.0012;

// ---- bloom approximation ----
uniform float bloom_amount : hint_range(0.0, 1.0) = 0.12;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.72;

// ---- flea overlay (0..1 = Flea Meter / 100) ----
uniform float flea : hint_range(0.0, 1.0) = 0.0;
uniform float flea_time = 0.0;                             // slow time, frozen under Reduced Motion
uniform float flea_motion : hint_range(0.0, 1.0) = 1.0;    // 0 = no pulse / crawl
uniform vec3 flea_color : source_color = vec3(1.0, 0.78, 0.25);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Drifting gold diamonds (stand-ins for the dollar-sign motes; TODO(resume): swap for a "$" glyph texture).
float motes(vec2 uv, float aspect, float t, float density) {
	vec2 g = uv * vec2(aspect, 1.0) * 13.0;
	g.y += t * 0.3;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash21(id);
	if (h > density) {
		return 0.0;
	}
	vec2 off = (vec2(hash21(id + 7.1), hash21(id + 3.3)) - 0.5) * 0.6;
	float size = 0.12 + 0.1 * hash21(id + 1.7);
	float dia = abs(f.x - off.x) + abs(f.y - off.y);
	float twinkle = 0.65 + 0.35 * sin(t * 1.4 + h * 40.0);   // slow: well under 3 Hz
	return smoothstep(size, size * 0.55, dia) * twinkle;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 c = uv - 0.5;
	float r = length(c * vec2(aspect, 1.0)) / (0.5 * length(vec2(aspect, 1.0)));   // 0 centre .. 1 corner

	// chromatic aberration: split R/B radially, stronger toward the edges
	vec2 shift = c * chroma_amount * (0.3 + r * 1.4) * (1.0 + flea * 1.5);
	vec3 col;
	col.r = texture(screen_tex, uv + shift).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - shift).b;

	// bloom approx: bright parts of a few blurred mip levels added back
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

	// vignette (pulses gently with the flea meter; slow, ~0.6 Hz)
	float pulse = 1.0 + flea * 0.45 * sin(flea_time * 3.8) * flea_motion;
	float vig = smoothstep(vignette_radius, vignette_radius + vignette_softness, r) * vignette_strength * (1.0 + flea * 0.6) * pulse;
	col = mix(col, vignette_color, clamp(vig, 0.0, 1.0));

	// grain
	float g = hash21(uv * vec2(1280.0, 720.0) + vec2(grain_seed * 17.0, grain_seed * 31.0)) - 0.5;
	col += g * grain_amount * (1.0 + flea * 0.8);

	// flea overlay: edge sparks crawl around the screen edge, gold motes from 70+
	if (flea > 0.001) {
		float edge = smoothstep(0.5, 1.0, r);
		float ang = atan(c.y, c.x);
		float n = vnoise(vec2(ang * 5.0 + 3.0, r * 3.0 - flea_time * 0.35 * flea_motion));
		float sparks = edge * smoothstep(0.5, 0.85, n) * flea;
		col = mix(col, flea_color, clamp(sparks * 0.55, 0.0, 0.7));
		col += flea_color * edge * flea * flea * 0.08;   // faint warm rim
		float dens = smoothstep(0.7, 1.0, flea) * 0.14 * (0.3 + 0.7 * r);   // thicker toward the edges
		if (dens > 0.0) {
			float m = motes(uv, aspect, flea_time, dens);
			col = mix(col, flea_color * 0.95, clamp(m, 0.0, 1.0));   // mix (not add) so motes stay gold on bright areas
		}
	}

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
