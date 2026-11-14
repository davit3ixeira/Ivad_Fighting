class_name StagePreview
extends RefCounted

const FLOOR_FRACTION := 0.82
const BUILDING_WIDTHS: Array[float] = [34.0, 22.0, 40.0, 28.0, 46.0, 24.0, 36.0, 30.0, 42.0, 38.0]
const BUILDING_HEIGHTS: Array[float] = [0.45, 0.3, 0.6, 0.38, 0.52, 0.28, 0.66, 0.4, 0.5, 0.35]
const COLUMN_SPOTS: Array[float] = [0.1, 0.3, 0.55, 0.78, 0.93]
const COLUMN_HEIGHTS: Array[float] = [0.55, 0.38, 0.62, 0.3, 0.48]
const SILHOUETTE := Color(0.03, 0.02, 0.07)


static func draw(canvas: CanvasItem, rect: Rect2, stage_index: int, clock: int) -> void:
	var stage := StageList.entry(stage_index)
	var top: Color = stage["sky_top"]
	var bottom: Color = stage["sky_bottom"]
	var line: Color = stage["line"]
	canvas.draw_primitive(
		PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]),
		PackedVector2Array()
	)
	match stage["id"]:
		"neon_city":
			_city(canvas, rect, line, clock)
		"pantheon_ruins":
			_ruins(canvas, rect, line, clock)
		_:
			_void(canvas, rect, line, clock)
	var floor_y := rect.position.y + rect.size.y * FLOOR_FRACTION
	canvas.draw_rect(Rect2(rect.position.x, floor_y, rect.size.x, rect.end.y - floor_y), Color(0.02, 0.02, 0.05, 0.9))
	canvas.draw_line(Vector2(rect.position.x, floor_y), Vector2(rect.end.x, floor_y), line, 2.0)


static func _city(canvas: CanvasItem, rect: Rect2, line: Color, clock: int) -> void:
	var floor_y := rect.position.y + rect.size.y * FLOOR_FRACTION
	var scale := rect.size.x / 340.0
	var x := rect.position.x
	for index in BUILDING_WIDTHS.size():
		if x >= rect.end.x:
			break
		var width := minf(BUILDING_WIDTHS[index] * scale, rect.end.x - x)
		var height := BUILDING_HEIGHTS[index] * rect.size.y
		canvas.draw_rect(Rect2(x, floor_y - height, width - 3.0, height), SILHOUETTE)
		if (index + clock / 20) % 3 == 0 and width > 14.0:
			canvas.draw_rect(Rect2(x + 4.0, floor_y - height + 10.0, width - 11.0, 5.0), Color(line, 0.9))
		x += width
	for drop in 16:
		var drop_x := rect.position.x + fmod(drop * 53.0 + clock * 1.5, rect.size.x - 6.0)
		var drop_y := rect.position.y + fmod(drop * 37.0 + clock * 6.0, rect.size.y * FLOOR_FRACTION - 12.0)
		canvas.draw_line(Vector2(drop_x, drop_y), Vector2(drop_x + 3.0, drop_y + 10.0), Color(0.7, 0.8, 1.0, 0.35), 1.0)


static func _ruins(canvas: CanvasItem, rect: Rect2, line: Color, clock: int) -> void:
	var floor_y := rect.position.y + rect.size.y * FLOOR_FRACTION
	var width := rect.size.x * 0.07
	for index in COLUMN_SPOTS.size():
		var center := rect.position.x + rect.size.x * COLUMN_SPOTS[index]
		var height := rect.size.y * COLUMN_HEIGHTS[index]
		var top := floor_y - height
		DrawKit.quad(canvas, Vector2(center - width * 0.5, floor_y), Vector2(center - width * 0.5, top + 6.0), Vector2(center + width * 0.5, top - 4.0), Vector2(center + width * 0.5, floor_y), SILHOUETTE)
		canvas.draw_rect(Rect2(center - width * 0.7, floor_y - 6.0, width * 1.4, 6.0), SILHOUETTE)
	for ember in 12:
		var ember_x := rect.position.x + fmod(ember * 61.0 + sin(clock * 0.03 + ember) * 8.0 + 20.0, rect.size.x - 4.0)
		var ember_y := floor_y - fmod(ember * 29.0 + clock * 0.9, rect.size.y * FLOOR_FRACTION - 6.0)
		canvas.draw_rect(Rect2(ember_x, ember_y, 2.5, 2.5), Color(line, 0.85))


static func _void(canvas: CanvasItem, rect: Rect2, line: Color, clock: int) -> void:
	for star in 30:
		var star_x := rect.position.x + fmod(star * 71.3, rect.size.x - 2.0)
		var star_y := rect.position.y + fmod(star * 43.1, rect.size.y * FLOOR_FRACTION - 4.0)
		canvas.draw_rect(Rect2(star_x, star_y, 2, 2), Color(1, 1, 1, 0.4 + 0.4 * sin(clock * 0.06 + star)))
	var center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.42)
	DrawKit.soft_disc(canvas, center + Vector2(-rect.size.x * 0.2, -10), rect.size.y * 0.3, Color(0.5, 0.25, 0.8, 0.35))
	DrawKit.ellipse_ring(canvas, center, Vector2(rect.size.x * 0.38, rect.size.y * 0.1), Color(line, 0.8), 2.0, -0.12 + sin(clock * 0.01) * 0.04)
	var floor_y := rect.position.y + rect.size.y * FLOOR_FRACTION
	DrawKit.quad(canvas, Vector2(rect.position.x + rect.size.x * 0.15, floor_y), Vector2(rect.end.x - rect.size.x * 0.15, floor_y), Vector2(rect.end.x - rect.size.x * 0.25, floor_y + 14.0), Vector2(rect.position.x + rect.size.x * 0.25, floor_y + 14.0), Color(line, 0.35))
