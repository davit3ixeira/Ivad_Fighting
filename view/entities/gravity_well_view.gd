class_name GravityWellView
extends EntityView

const CORE_RADIUS := 22.0
const ORBIT_STARS := 6
const PULL_STREAKS := 5


func draw_solid(canvas: CanvasItem) -> void:
	DrawKit.disc(canvas, Vector2.ZERO, CORE_RADIUS * fade(), Color(0.01, 0.0, 0.03, 0.95))


func draw_glow(canvas: CanvasItem) -> void:
	var strength := fade()
	var pulse := 1.0 + 0.08 * sin(age * 0.4)
	DrawKit.ring(canvas, Vector2.ZERO, (CORE_RADIUS + 2.0) * pulse * strength, Color(power_color, strength), 3.0)
	DrawKit.ellipse_ring(canvas, Vector2.ZERO, Vector2(48, 14) * strength, Color(power_color, 0.7 * strength), 2.0, age * 0.07)
	DrawKit.ellipse_ring(canvas, Vector2.ZERO, Vector2(62, 11) * strength, Color(1, 1, 1, 0.35 * strength), 1.5, -age * 0.05 + 1.2)
	for index in ORBIT_STARS:
		var angle := age * 0.16 + TAU * index / ORBIT_STARS
		var distance := 58.0 - float((age * 2 + index * 8) % 40)
		DrawKit.star(canvas, Vector2(cos(angle), sin(angle)) * distance, 4.5 * strength, Color(1, 1, 1, 0.85 * strength), angle)
	for index in PULL_STREAKS:
		var angle := TAU * index / PULL_STREAKS + 0.6
		var travel := float((age * 4 + index * 23) % 90)
		var outer := 150.0 - travel
		var dir := Vector2(cos(angle), sin(angle) * 0.5)
		canvas.draw_line(dir * outer, dir * (outer - 22.0), Color(power_color, 0.35 * strength * travel / 90.0), 2.0)
