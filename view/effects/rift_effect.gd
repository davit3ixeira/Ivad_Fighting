class_name RiftEffect
extends Node2D

const LIFETIME := 18
const HEIGHT := 190.0
const MAX_WIDTH := 30.0
const STAR_COUNT := 6

var _color: Color = Color.WHITE
var _frame: int = 0


func setup(_config: Dictionary, params: Dictionary) -> void:
	_color = params.get("color", Color.WHITE)
	material = DrawKit.additive_material()


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _frame >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := float(_frame) / LIFETIME
	var open := sin(t * PI)
	var half_height := HEIGHT * 0.5 * (0.4 + 0.6 * open)
	var half_width := MAX_WIDTH * 0.5 * open
	_draw_slit(half_width * 2.2, half_height * 1.1, Color(_color, 0.3 * open))
	_draw_slit(half_width * 1.4, half_height, Color(_color, 0.8 * open))
	_draw_slit(half_width * 0.6, half_height * 0.9, Color(1, 1, 1, 0.95 * open))
	for index in STAR_COUNT:
		var along := -1.0 + 2.0 * (float(index) + 0.5) / STAR_COUNT
		var side := 1.0 if index % 2 == 0 else -1.0
		var point := Vector2(side * (half_width + 10.0 + 26.0 * t), along * half_height)
		DrawKit.star(self, point, 6.0 * open, Color(1, 1, 1, open), t * 3.0 + index)


func _draw_slit(half_width: float, half_height: float, color: Color) -> void:
	if half_width < 0.5:
		return
	DrawKit.diamond(self, Vector2.ZERO, half_width, half_height, color)
