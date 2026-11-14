class_name UiKit
extends RefCounted

const SCREEN_SIZE := Vector2(1280, 720)
const P1_COLOR := Color(0.25, 0.6, 1.0)
const P2_COLOR := Color(1.0, 0.25, 0.3)
const ACCENT_COLOR := Color(0.62, 0.42, 1.0)
const TEXT_COLOR := Color(0.93, 0.94, 1.0)
const DIM_TEXT_COLOR := Color(0.62, 0.66, 0.82)
const HINT_COLOR := Color(0.52, 0.57, 0.78)
const GOLD_COLOR := Color(1.0, 0.86, 0.4)
const WARNING_COLOR := Color(1.0, 0.65, 0.3)
const PANEL_COLOR := Color(0.03, 0.03, 0.08, 0.9)
const HINT_MENU := "Direcional escolhe    X ou □ confirma    ○ volta        Teclado: K/J confirma, I volta  |  Num2/Num1 confirma, Num5 volta"
const HINT_Y := 702.0


static func player_color(slot: int) -> Color:
	return P1_COLOR if slot == 0 else P2_COLOR


static func font() -> Font:
	return ThemeDB.fallback_font


static func fill_screen(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func text(canvas: CanvasItem, at: Vector2, value: String, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, glow: bool = true) -> void:
	var face := font()
	if glow:
		canvas.draw_string_outline(face, at, value, align, width, font_size, maxi(int(font_size / 6.0), 3), Color(color, color.a * 0.3))
	canvas.draw_string(face, at, value, align, width, font_size, color)


static func centered(canvas: CanvasItem, y: float, value: String, font_size: int, color: Color, glow: bool = true) -> void:
	text(canvas, Vector2(0, y), value, font_size, color, SCREEN_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER, glow)


static func panel(canvas: CanvasItem, rect: Rect2, border: Color, fill: Color = PANEL_COLOR, width: float = 2.0) -> void:
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect.grow(3.0), Color(border, border.a * 0.18), false, 5.0)
	canvas.draw_rect(rect, border, false, width)


static func hint(canvas: CanvasItem, value: String = HINT_MENU) -> void:
	centered(canvas, HINT_Y, value, 14, HINT_COLOR, false)


static func blink(clock: int, period: int = 30) -> bool:
	return (clock / period) % 2 == 0
