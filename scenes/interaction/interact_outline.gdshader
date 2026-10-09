shader_type spatial;
// Inverted-hull outline used as material_overlay on the focused interactable. (F-02)
render_mode cull_front, unshaded, depth_draw_never, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(1.0, 0.86, 0.42, 1.0);
uniform float width : hint_range(0.0, 0.2) = 0.03;
// 0 = steady (Reduced Motion), 1 = gentle slow pulse (well under 3 Hz).
uniform float pulse : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	float p = 1.0 - 0.25 * pulse * (0.5 + 0.5 * sin(TIME * 2.4));
	ALBEDO = outline_color.rgb * p;
}
