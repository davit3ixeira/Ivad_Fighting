class_name SingularityView
extends EntityView

const CORE_RADIUS := 36.0
const INFALL_STARS := 12
const INFALL_RADIUS := 230.0
const DISK_RINGS := 3


func _core_scale() -> float:
	var grow := minf(age / 10.0, 1.0)
	if entity.vars.has("nova"):
		return 0.0
	return grow * fade() * (1.0 + 0.06 * sin(age * 0.7))


func draw_solid(canvas: CanvasItem) -> void:
	var radius := CORE_RADIUS * _core_scale()
	if radius > 1.0:
		DrawKit.disc(canvas, Vector2.ZERO, radius, Color(0.0, 0.0, 0.01, 1.0))


func draw_glow(canvas: CanvasItem) -> void:
	var scale_now := _core_scale()
	if scale_now <= 0.01:
		return
	DrawKit.ring(canvas, Vector2.ZERO, (CORE_RADIUS + 3.0) * scale_now, Color(1, 1, 1, 0.95), 3.5, 36)
	DrawKit.ring(canvas, Vector2.ZERO, (CORE_RADIUS + 12.0) * scale_now, Color(power_color, 0.6), 5.0, 36)
	for index in DISK_RINGS:
		var radii := Vector2(70.0 + index * 26.0, 14.0 + index * 5.0) * scale_now
		var spin := age * (0.09 - index * 0.02) + index * 0.7
		DrawKit.ellipse_ring(canvas, Vector2.ZERO, radii, Color(power_color, 0.75 - index * 0.18), 2.5, spin, 32)
	for index in INFALL_STARS:
		var cycle := float((age * 5 + index * 37) % 100) / 100.0
		var distance := INFALL_RADIUS * (1.0 - cycle) + CORE_RADIUS
		var angle := TAU * index / INFALL_STARS + cycle * 2.4 + age * 0.02
		var point := Vector2(cos(angle), sin(angle) * 0.75) * distance
		DrawKit.star(canvas, point, 3.0 + 5.0 * cycle, Color(1, 1, 1, 0.3 + 0.6 * cycle), angle)
		canvas.draw_line(point, point * 1.12, Color(power_color, 0.35 * cycle), 2.0)
