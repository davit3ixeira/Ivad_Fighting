class_name MenuBackdrop
extends RefCounted

const TOP_COLOR := Color(0.015, 0.012, 0.05)
const BOTTOM_COLOR := Color(0.07, 0.025, 0.12)
const HORIZON_Y := 470.0
const VANISH_X := 640.0
const GRID_COLUMNS := 11
const GRID_ROWS := 9
const STAR_COUNT := 40


static func draw(canvas: CanvasItem, clock: int, accent: Color = UiKit.ACCENT_COLOR) -> void:
	var size := UiKit.SCREEN_SIZE
	canvas.draw_primitive(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([TOP_COLOR, TOP_COLOR, BOTTOM_COLOR, BOTTOM_COLOR]),
		PackedVector2Array()
	)
	for index in STAR_COUNT:
		var x := fmod(index * 197.3, size.x)
		var y := fmod(index * 83.7, HORIZON_Y - 40.0)
		var twinkle := 0.35 + 0.35 * sin(clock * 0.05 + index * 1.7)
		canvas.draw_rect(Rect2(x, y, 2, 2), Color(1, 1, 1, twinkle))
	for column in range(-GRID_COLUMNS, GRID_COLUMNS + 1):
		canvas.draw_line(Vector2(VANISH_X + column * 14.0, HORIZON_Y), Vector2(VANISH_X + column * 150.0, size.y), Color(accent, 0.16), 1.5)
	for row in GRID_ROWS:
		var t := fmod(float(row) / GRID_ROWS + clock * 0.004, 1.0)
		var y := HORIZON_Y + t * t * (size.y - HORIZON_Y)
		canvas.draw_line(Vector2(0, y), Vector2(size.x, y), Color(accent, 0.05 + 0.22 * t), 1.5)
	canvas.draw_line(Vector2(0, HORIZON_Y), Vector2(size.x, HORIZON_Y), Color(accent, 0.18), 10.0)
	canvas.draw_line(Vector2(0, HORIZON_Y), Vector2(size.x, HORIZON_Y), Color(accent, 0.8), 2.0)
