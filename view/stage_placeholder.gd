class_name StagePlaceholder
extends Node2D

const FLOOR_COLOR := Color(0.03, 0.03, 0.07)
const DRAW_MARGIN := 700.0
const SKY_HEIGHT := 1300.0
const FLOOR_DEPTH := 500.0
const GRID_SPACING := 160.0

var _sky_top: Color = Color(0.02, 0.02, 0.06)
var _sky_bottom: Color = Color(0.07, 0.05, 0.14)
var _line_color: Color = Color(0.35, 0.3, 0.8)


func apply(stage_index: int) -> void:
	var stage := StageList.entry(stage_index)
	_sky_top = stage["sky_top"]
	_sky_bottom = stage["sky_bottom"]
	_line_color = stage["line"]
	queue_redraw()


func _draw() -> void:
	var half := GlobalTuning.STAGE_HALF_WIDTH
	var left := -half - DRAW_MARGIN
	var width := (half + DRAW_MARGIN) * 2.0
	var floor_y := GlobalTuning.FLOOR_Y
	var sky := PackedVector2Array([
		Vector2(left, floor_y - SKY_HEIGHT), Vector2(left + width, floor_y - SKY_HEIGHT),
		Vector2(left + width, floor_y), Vector2(left, floor_y),
	])
	draw_polygon(sky, PackedColorArray([_sky_top, _sky_top, _sky_bottom, _sky_bottom]))
	var x := -half
	while x <= half + 0.5:
		draw_line(Vector2(x, floor_y - 520.0), Vector2(x, floor_y), Color(_line_color, 0.12), 2.0)
		x += GRID_SPACING
	draw_rect(Rect2(left, floor_y, width, FLOOR_DEPTH), FLOOR_COLOR)
	draw_line(Vector2(left, floor_y), Vector2(left + width, floor_y), Color(_line_color, 0.25), 8.0)
	draw_line(Vector2(left, floor_y), Vector2(left + width, floor_y), _line_color, 2.5)
	for wall_x in [-half, half]:
		draw_line(Vector2(wall_x, floor_y - 600.0), Vector2(wall_x, floor_y), Color(_line_color, 0.25), 10.0)
		draw_line(Vector2(wall_x, floor_y - 600.0), Vector2(wall_x, floor_y), _line_color, 3.0)
