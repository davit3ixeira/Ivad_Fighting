class_name IntroOverlay
extends Control

const NAME_SLIDE_FRAMES := 14
const LINE_START: Array[int] = [18, 64]
const LINE_DURATION := 62
const LINE_FADE := 8
const FIGHT_CALL_FRAMES := 50
const FIGHT_CALL_POP_FRAMES := 8
const BAND := Rect2(0, 176, 1280, 220)
const NAME_Y := 268.0
const LINE_Y: Array[float] = [326.0, 364.0]
const SIDE_MARGIN := 80.0
const SLIDE_DISTANCE := 560.0
const FIGHT_TEXT := "LUTAR!"

var _active: bool = false
var _clock: int = 0
var _call_clock: int = -1
var _names: Array[String] = ["", ""]
var _lines: Array[String] = ["", ""]


func _ready() -> void:
	UiKit.fill_screen(self)
	visible = false


func begin(p1_name: String, p2_name: String, p1_line: String, p2_line: String) -> void:
	_names = [p1_name.to_upper(), p2_name.to_upper()]
	_lines = [p1_line, p2_line]
	_active = true
	_clock = 0
	_call_clock = -1
	visible = true
	queue_redraw()


func call_fight() -> void:
	_active = false
	_call_clock = 0
	visible = true


func finish() -> void:
	_active = false
	_call_clock = -1
	visible = false


func refresh() -> void:
	if not visible:
		return
	_clock += 1
	if _call_clock >= 0:
		_call_clock += 1
		if _call_clock > FIGHT_CALL_FRAMES:
			finish()
	queue_redraw()


func _draw() -> void:
	if _active:
		_draw_names()
	if _call_clock >= 0:
		_draw_fight_call()


func _draw_names() -> void:
	var slide := 1.0 - pow(1.0 - minf(float(_clock) / NAME_SLIDE_FRAMES, 1.0), 3.0)
	var offset := (1.0 - slide) * SLIDE_DISTANCE
	draw_rect(BAND, Color(0, 0, 0.03, 0.6 * slide))
	draw_line(Vector2(0, BAND.position.y), Vector2(BAND.end.x, BAND.position.y), Color(UiKit.ACCENT_COLOR, 0.6 * slide), 2.0)
	draw_line(Vector2(0, BAND.end.y), Vector2(BAND.end.x, BAND.end.y), Color(UiKit.ACCENT_COLOR, 0.6 * slide), 2.0)
	var width := UiKit.SCREEN_SIZE.x - SIDE_MARGIN * 2.0
	UiKit.text(self, Vector2(SIDE_MARGIN - offset, NAME_Y), _names[0], 64, UiKit.P1_COLOR, width, HORIZONTAL_ALIGNMENT_LEFT)
	UiKit.text(self, Vector2(SIDE_MARGIN + offset, NAME_Y), _names[1], 64, UiKit.P2_COLOR, width, HORIZONTAL_ALIGNMENT_RIGHT)
	UiKit.centered(self, NAME_Y - 6.0, "VS", 44, Color(UiKit.TEXT_COLOR, slide))
	for slot in 2:
		var alpha := _line_alpha(slot)
		if alpha <= 0.0 or _lines[slot] == "":
			continue
		var align := HORIZONTAL_ALIGNMENT_LEFT if slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		var quote := "“%s”" % _lines[slot]
		UiKit.text(self, Vector2(SIDE_MARGIN, LINE_Y[slot]), quote, 22, Color(UiKit.TEXT_COLOR, alpha), width, align, false)


func _line_alpha(slot: int) -> float:
	var local := _clock - LINE_START[slot]
	if local < 0 or local > LINE_DURATION:
		return 0.0
	return minf(minf(float(local) / LINE_FADE, float(LINE_DURATION - local) / LINE_FADE), 1.0)


func _draw_fight_call() -> void:
	var t := float(_call_clock) / FIGHT_CALL_FRAMES
	var pop := 1.0 + 0.35 * maxf(1.0 - float(_call_clock) / FIGHT_CALL_POP_FRAMES, 0.0)
	var alpha := 1.0 - maxf((t - 0.65) / 0.35, 0.0)
	var center := UiKit.SCREEN_SIZE * 0.5
	draw_set_transform(center, 0.0, Vector2(pop, pop))
	UiKit.text(self, Vector2(-UiKit.SCREEN_SIZE.x * 0.5, 40.0), FIGHT_TEXT, 120, Color(UiKit.GOLD_COLOR, alpha), UiKit.SCREEN_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
