class_name StagePlaceholder
extends Node2D

const SKY_TOP := Color(0.02, 0.02, 0.06)
const SKY_BOTTOM := Color(0.07, 0.05, 0.14)
const FLOOR_COLOR := Color(0.03, 0.03, 0.07)
const LINE_COLOR := Color(0.35, 0.3, 0.8)
const GRID_COLOR := Color(0.3, 0.3, 0.7, 0.12)
const DRAW_MARGIN := 700.0
const SKY_HEIGHT := 1300.0
const FLOOR_DEPTH := 500.0
const GRID_SPACING := 160.0


func _draw() -> void:
	var half := GlobalTuning.STAGE_HALF_WIDTH
	var left := -half - DRAW_MARGIN
	var width := (half + DRAW_MARGIN) * 2.0
	var floor_y := GlobalTuning.FLOOR_Y
	var sky := PackedVector2Array([
		Vector2(left, floor_y - SKY_HEIGHT), Vector2(left + width, floor_y - SKY_HEIGHT),
		Vector2(left + width, floor_y), Vector2(left, floor_y),
	])
	draw_polygon(sky, PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM]))
	var x := -half
	while x <= half + 0.5:
		draw_line(Vector2(x, floor_y - 520.0), Vector2(x, floor_y), GRID_COLOR, 2.0)
		x += GRID_SPACING
	draw_rect(Rect2(left, floor_y, width, FLOOR_DEPTH), FLOOR_COLOR)
	draw_line(Vector2(left, floor_y), Vector2(left + width, floor_y), Color(LINE_COLOR, 0.25), 8.0)
	draw_line(Vector2(left, floor_y), Vector2(left + width, floor_y), LINE_COLOR, 2.5)
	for wall_x in [-half, half]:
		draw_line(Vector2(wall_x, floor_y - 600.0), Vector2(wall_x, floor_y), Color(LINE_COLOR, 0.25), 10.0)
		draw_line(Vector2(wall_x, floor_y - 600.0), Vector2(wall_x, floor_y), LINE_COLOR, 3.0)
