class_name CosmicMarkView
extends EntityView

const BEAM_HEIGHT := 86.0
const EXPIRE_WARNING_FRAMES := 120


func draw_glow(canvas: CanvasItem) -> void:
	var strength := fade()
	var remaining := entity.data.lifetime - entity.frame
	if remaining < EXPIRE_WARNING_FRAMES and (age / 6) % 2 == 0:
		strength *= 0.35
	var pulse := 1.0 + 0.12 * sin(age * 0.15)
	DrawKit.ellipse_ring(canvas, Vector2(0, -2), Vector2(34, 8) * pulse, Color(power_color, 0.9 * strength), 2.5)
	DrawKit.ellipse_ring(canvas, Vector2(0, -2), Vector2(22, 5), Color(player_color, 0.9 * strength), 2.0)
	canvas.draw_line(Vector2(0, -4), Vector2(0, -BEAM_HEIGHT), Color(power_color, 0.22 * strength), 7.0)
	canvas.draw_line(Vector2(0, -4), Vector2(0, -BEAM_HEIGHT * 0.7), Color(1, 1, 1, 0.3 * strength), 2.0)
	var hover := -24.0 + 4.0 * sin(age * 0.1)
	DrawKit.star(canvas, Vector2(0, hover), 11.0 * strength, Color(1, 1, 1, 0.95 * strength), age * 0.03)
	DrawKit.star(canvas, Vector2(0, hover), 17.0 * strength, Color(power_color, 0.4 * strength), -age * 0.03)
