class_name Horns
extends RefCounted

const SEGMENTS := 6
const FAR_SHADE := 0.3
const FAR_SCALE := 0.88

var anchor: String = "head"
var near_base: Vector2 = Vector2(5, -11)
var far_base: Vector2 = Vector2(-3, -13)
var control: Vector2 = Vector2(12, -34)
var tip: Vector2 = Vector2(-14, -54)
var base_width: float = 10.0
var tip_width: float = 2.0
var fill_color: Color = Color(0.16, 0.1, 0.08)
var highlight_color: Color = Color(1.0, 0.55, 0.25)


func configure(config: Dictionary) -> void:
	for field in config:
		if field != "type":
			set(field, config[field])


func update(_view: FighterView) -> void:
	pass


func draw(canvas: CanvasItem, view: FighterView, color: Color, extra: float, is_fill: bool) -> void:
	var paint := view.tinted(fill_color.darkened(FAR_SHADE)) if is_fill else color
	_draw_horn(canvas, view, far_base, FAR_SCALE, paint, extra, false)


func draw_front(canvas: CanvasItem, view: FighterView, color: Color, extra: float, is_fill: bool) -> void:
	var paint := view.tinted(fill_color) if is_fill else color
	_draw_horn(canvas, view, near_base, 1.0, paint, extra, is_fill)


func _draw_horn(canvas: CanvasItem, view: FighterView, base: Vector2, size: float, paint: Color, extra: float, shine: bool) -> void:
	if not view.joints.has(anchor):
		return
	var start: Vector2 = view.joints[anchor] + base
	var previous := start
	for index in range(1, SEGMENTS + 1):
		var t := float(index) / SEGMENTS
		var point := _bezier(start, start + control * size, start + tip * size, t)
		var width := lerpf(base_width, tip_width, t) * size + extra
		canvas.draw_line(previous, point, paint, width)
		DrawKit.disc(canvas, point, width * 0.5, paint)
		if shine:
			canvas.draw_line(previous, point, Color(highlight_color, 0.7), 1.5)
		previous = point
	DrawKit.disc(canvas, start, (base_width * size + extra) * 0.5, paint)


func _bezier(from: Vector2, middle: Vector2, to: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return from * inverse * inverse + middle * 2.0 * inverse * t + to * t * t
