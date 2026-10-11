class_name FaceAtlas
extends RefCounted
## Procedural expression atlas for the character kit. (F-12)
##
## `FaceAtlas.build(style)` draws every expression into ONE transparent texture (4 x 3 cells of 128 px; the face
## quad on a head shows one cell at a time, skin shows through the transparent parts). `cell_uv(name)` returns the
## normalised UV rect of an expression's cell. Style keys (all optional): eye_color, brow_color, mouth_color,
## lash (bool, heavier upper lid), brow_width (px).
##
##     var tex := FaceAtlas.build({"eye_color": Color(0.25, 0.5, 0.9)})
##     var r := FaceAtlas.cell_uv("glare")        # Rect2(position=uv offset, size=uv scale)

const COLS := 4
const ROWS := 3
const CELL := 128
const EXPRESSIONS: Array[String] = ["neutral", "smile", "sly_smile", "stern", "glare", "worried", "angry",
	"surprised", "eyes_closed", "sad"]

const DEFAULT_STYLE := {
	"eye_color": Color(0.32, 0.22, 0.14), "brow_color": Color(0.16, 0.11, 0.08),
	"mouth_color": Color(0.45, 0.14, 0.14), "lash": false, "brow_width": 4.0,
}


## True if `expr` is one of EXPRESSIONS.
static func has(expr: String) -> bool:
	return EXPRESSIONS.has(expr)


## Normalised UV rectangle of the cell holding expression `expr` (neutral if unknown).
static func cell_uv(expr: String) -> Rect2:
	var i := maxi(0, EXPRESSIONS.find(expr))
	return Rect2(Vector2(float(i % COLS) / COLS, float(i / COLS) / ROWS), Vector2(1.0 / COLS, 1.0 / ROWS))


## Draws the whole atlas for `style` and returns it as a texture.
static func build(style: Dictionary = {}) -> ImageTexture:
	var s := DEFAULT_STYLE.duplicate()
	s.merge(style, true)
	var img := Image.create(COLS * CELL, ROWS * CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in EXPRESSIONS.size():
		_draw_face(img, Vector2((i % COLS) * CELL, (i / COLS) * CELL), EXPRESSIONS[i], s)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ drawing

static func _draw_face(img: Image, o: Vector2, e: String, s: Dictionary) -> void:
	var bw: float = s["brow_width"]
	var bc: Color = s["brow_color"]
	var mc: Color = s["mouth_color"]
	# eye: [openness 0..1, lid tilt, radius]; brow: [inner_y, outer_y, raise]; mouth: [left_y, mid_y, right_y, open_disc_r]
	var eye := [1.0, 0.0, 11.0]
	var brow := [0.0, 0.0, 0.0]
	var mouth := [0.0, 0.0, 0.0, 0.0]
	var brow_right_extra := 0.0     # sly: right brow raised
	match e:
		"neutral":
			mouth = [0.0, 1.5, 0.0, 0.0]
		"smile":
			eye = [0.9, 0.0, 11.0]; brow = [0.0, -1.0, -2.0]; mouth = [-6.0, 7.0, -6.0, 0.0]
		"sly_smile":
			eye = [0.62, 0.0, 11.0]; brow = [0.0, 0.0, 0.0]; mouth = [2.0, 5.0, -8.0, 0.0]; brow_right_extra = -6.0
		"stern":
			eye = [0.85, 0.12, 11.0]; brow = [2.0, -1.0, 2.0]; mouth = [1.0, 0.0, 1.0, 0.0]
		"glare":
			eye = [0.55, 0.32, 11.5]; brow = [7.0, -3.0, 3.0]; mouth = [2.0, -1.0, 2.0, 0.0]
		"worried":
			eye = [1.0, -0.15, 11.0]; brow = [-6.0, 3.0, -2.0]; mouth = [3.0, -3.0, 3.0, 0.0]
		"angry":
			eye = [0.7, 0.4, 11.0]; brow = [9.0, -4.0, 2.0]; mouth = [5.0, -5.0, 5.0, 0.0]
		"surprised":
			eye = [1.0, 0.0, 14.0]; brow = [-3.0, -3.0, -9.0]; mouth = [0.0, 0.0, 0.0, 8.0]
		"eyes_closed":
			eye = [0.0, 0.0, 11.0]; mouth = [-2.0, 3.0, -2.0, 0.0]
		"sad":
			eye = [0.9, -0.1, 11.0]; brow = [-5.0, 2.0, 0.0]; mouth = [4.0, -4.0, 4.0, 0.0]

	var ey := 52.0
	for side in [-1, 1]:
		var cx: float = 64.0 + float(side) * 24.0
		# tilt sign: positive tilt = lids slope down toward the nose (angry look)
		var tilt: float = eye[1] * (-side)
		_eye(img, o, Vector2(cx, ey), eye[2], eye[0], tilt, s)
		var inner_x: float = cx - float(side) * 13.0
		var outer_x: float = cx + float(side) * 13.0
		var by: float = ey - eye[2] - 8.0 + brow[2]
		var inner_y: float = by + brow[0]
		var outer_y: float = by + brow[1]
		if brow_right_extra != 0.0 and side == 1:
			inner_y += brow_right_extra
			outer_y += brow_right_extra
		_line(img, o + Vector2(inner_x, inner_y), o + Vector2(outer_x, outer_y), bw, bc)
	# mouth
	var my := 96.0
	var l := Vector2(46.0, my + mouth[0])
	var m := Vector2(64.0, my + mouth[1])
	var r := Vector2(82.0, my + mouth[2])
	if mouth[3] > 0.0:
		_disc(img, o + Vector2(64.0, my + 2.0), mouth[3], mc)
		_disc(img, o + Vector2(64.0, my + 2.0), mouth[3] - 3.0, Color(0.2, 0.05, 0.07))
	else:
		_curve(img, o + l, o + m, o + r, 3.2, mc)


static func _eye(img: Image, o: Vector2, c: Vector2, r: float, openness: float, tilt: float, s: Dictionary) -> void:
	var bc: Color = s["brow_color"]
	if openness <= 0.02:
		# closed: a downward arc
		_curve(img, o + c + Vector2(-r, 0), o + c + Vector2(0, 5.0), o + c + Vector2(r, 0), 3.0, bc)
		return
	var top := c.y - r + (1.0 - openness) * 2.0 * r      # first visible row (lid line)
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var d := Vector2(x, y) - c
			if d.length() > r:
				continue
			if float(y) < top + tilt * (float(x) - c.x):
				continue
			var col := Color.WHITE
			if d.length() <= r * 0.62:
				col = s["eye_color"]
			if d.length() <= r * 0.3:
				col = Color(0.04, 0.03, 0.05)
			_put(img, o + Vector2(x, y), col)
	# lid line along the cut
	var lw: float = 3.0 if s["lash"] else 2.0
	_line(img, o + Vector2(c.x - r, top + tilt * -r), o + Vector2(c.x + r, top + tilt * r), lw + (1.5 if s["lash"] else 0.0), bc)


static func _put(img: Image, p: Vector2, col: Color) -> void:
	var x := int(p.x)
	var y := int(p.y)
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, col)


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if Vector2(x, y).distance_to(c) <= r:
				_put(img, Vector2(x, y), col)


static func _line(img: Image, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var n := maxi(2, int(a.distance_to(b) * 1.5))
	for i in n + 1:
		_disc(img, a.lerp(b, float(i) / n), w * 0.5, col)


## Quadratic curve a -> (control m) -> b drawn as a thick polyline; `m` is the curve's mid POINT (not the control).
static func _curve(img: Image, a: Vector2, m: Vector2, b: Vector2, w: float, col: Color) -> void:
	var ctrl := m * 2.0 - (a + b) * 0.5      # so the curve actually passes through m at t = 0.5
	var prev := a
	for i in range(1, 17):
		var t := float(i) / 16.0
		var p := a * (1.0 - t) * (1.0 - t) + ctrl * 2.0 * (1.0 - t) * t + b * t * t
		_line(img, prev, p, w, col)
		prev = p
