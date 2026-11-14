class_name FightHud
extends Control

const P1_COLOR := Color(0.25, 0.6, 1.0)
const P2_COLOR := Color(1.0, 0.25, 0.3)
const HEALTH_COLOR := Color(0.95, 0.95, 0.75)
const GHOST_COLOR := Color(1.0, 0.35, 0.2, 0.85)
const BACK_COLOR := Color(0.02, 0.02, 0.05, 0.85)
const METER_COLOR := Color(0.5, 0.9, 1.0)
const METER_FULL_COLOR := Color(1.0, 0.95, 0.5)

const SCREEN_WIDTH := 1280.0
const SCREEN_HEIGHT := 720.0
const BAR_MARGIN := 60.0
const BAR_GAP := 100.0
const BAR_TOP := 38.0
const BAR_HEIGHT := 22.0
const METER_WIDTH := 300.0
const METER_TOP := 672.0
const METER_HEIGHT := 12.0
const GAUGE_WIDTH := 120.0
const GAUGE_HEIGHT := 6.0
const GAUGE_TOP := 646.0
const GHOST_SPEED := 4.0
const GHOST_DELAY_FRAMES := 30
const FLASH_DECAY := 0.09
const BANNER_FADE_FRAMES := 12

var sim: FightSim
var center_title: String = ""
var center_subtitle: String = ""

var _ghost: Array[float] = [0.0, 0.0]
var _ghost_hold: Array[int] = [0, 0]
var _last_health: Array[int] = [0, 0]
var _font: Font
var _clock: int = 0
var _flash_color: Color = Color.WHITE
var _flash_amount: float = 0.0
var _banner_text: String = ""
var _banner_color: Color = Color.WHITE
var _banner_frames: int = 0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(target: FightSim) -> void:
	sim = target
	reset()


func reset() -> void:
	for slot in 2:
		_ghost[slot] = sim.fighters[slot].health
		_last_health[slot] = sim.fighters[slot].health
		_ghost_hold[slot] = 0
	center_title = ""
	center_subtitle = ""
	_banner_frames = 0
	_flash_amount = 0.0


func flash(color: Color, strength: float) -> void:
	_flash_color = color
	_flash_amount = maxf(_flash_amount, strength)


func show_banner(text: String, color: Color, frames: int) -> void:
	_banner_text = text
	_banner_color = color
	_banner_frames = frames


func refresh() -> void:
	_clock += 1
	_flash_amount = maxf(_flash_amount - FLASH_DECAY, 0.0)
	if _banner_frames > 0:
		_banner_frames -= 1
	for slot in 2:
		var health := sim.fighters[slot].health
		if health < _last_health[slot]:
			_ghost_hold[slot] = GHOST_DELAY_FRAMES
		_last_health[slot] = health
		if _ghost_hold[slot] > 0:
			_ghost_hold[slot] -= 1
		elif _ghost[slot] > health:
			_ghost[slot] = maxf(_ghost[slot] - GHOST_SPEED, health)
		if _ghost[slot] < health:
			_ghost[slot] = health
	queue_redraw()


func _draw() -> void:
	if sim == null or sim.fighters.size() < 2:
		return
	if _flash_amount > 0.0:
		draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(_flash_color, _flash_amount))
	var bar_width := (SCREEN_WIDTH - BAR_MARGIN * 2.0 - BAR_GAP) * 0.5
	_draw_health(0, Rect2(BAR_MARGIN, BAR_TOP, bar_width, BAR_HEIGHT), true)
	_draw_health(1, Rect2(SCREEN_WIDTH - BAR_MARGIN - bar_width, BAR_TOP, bar_width, BAR_HEIGHT), false)
	_draw_meter(0, Rect2(BAR_MARGIN, METER_TOP, METER_WIDTH, METER_HEIGHT), false)
	_draw_meter(1, Rect2(SCREEN_WIDTH - BAR_MARGIN - METER_WIDTH, METER_TOP, METER_WIDTH, METER_HEIGHT), true)
	_draw_gauges(0)
	_draw_gauges(1)
	_draw_names(bar_width)
	_draw_combo(0)
	_draw_combo(1)
	_draw_banner()
	_draw_center()


func _player_color(slot: int) -> Color:
	return P1_COLOR if slot == 0 else P2_COLOR


func _draw_health(slot: int, rect: Rect2, anchored_right: bool) -> void:
	var fighter := sim.fighters[slot]
	var color := _player_color(slot)
	var max_health := float(fighter.data.health)
	draw_rect(rect.grow(5.0), Color(color, 0.12))
	draw_rect(rect, BACK_COLOR)
	_draw_fill(rect, _ghost[slot] / max_health, anchored_right, GHOST_COLOR)
	_draw_fill(rect, fighter.health / max_health, anchored_right, HEALTH_COLOR)
	draw_rect(rect, color, false, 2.0)


func _draw_meter(slot: int, rect: Rect2, anchored_right: bool) -> void:
	var fighter := sim.fighters[slot]
	var color := _player_color(slot)
	var fraction := float(fighter.meter) / GlobalTuning.METER_MAX
	var full := fraction >= 1.0
	draw_rect(rect.grow(4.0), Color(color, 0.1))
	draw_rect(rect, BACK_COLOR)
	_draw_fill(rect, fraction, anchored_right, METER_FULL_COLOR if full else METER_COLOR)
	draw_rect(rect, color, false, 1.5)
	if full and (_clock / 10) % 2 == 0:
		var alignment := HORIZONTAL_ALIGNMENT_RIGHT if anchored_right else HORIZONTAL_ALIGNMENT_LEFT
		draw_string(_font, Vector2(rect.position.x, rect.end.y + 22.0), "SUPREMO PRONTO", alignment, rect.size.x, 16, METER_FULL_COLOR)


func _draw_gauges(slot: int) -> void:
	var fighter := sim.fighters[slot]
	var gauges := fighter.hud_gauges()
	var color := fighter.data.power_color
	for index in gauges.size():
		var gauge: Dictionary = gauges[index]
		var top := GAUGE_TOP - index * 24.0
		var x := BAR_MARGIN if slot == 0 else SCREEN_WIDTH - BAR_MARGIN - GAUGE_WIDTH
		var rect := Rect2(x, top, GAUGE_WIDTH, GAUGE_HEIGHT)
		var active: bool = gauge.get("active", true)
		var paint := color if active else Color(color, 0.3)
		draw_rect(rect, BACK_COLOR)
		_draw_fill(rect, gauge.get("fraction", 0.0), slot == 1, paint)
		draw_rect(rect, paint, false, 1.0)
		var label_x := x + GAUGE_WIDTH + 10.0 if slot == 0 else x - 10.0 - 200.0
		var alignment := HORIZONTAL_ALIGNMENT_LEFT if slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		draw_string(_font, Vector2(label_x, top + 9.0), gauge.get("label", ""), alignment, 200.0, 14, paint)


func _draw_fill(rect: Rect2, fraction: float, anchored_right: bool, color: Color) -> void:
	var width := rect.size.x * clampf(fraction, 0.0, 1.0)
	if width <= 0.0:
		return
	var x := rect.end.x - width if anchored_right else rect.position.x
	draw_rect(Rect2(x, rect.position.y, width, rect.size.y), color)


func _draw_names(bar_width: float) -> void:
	var y := BAR_TOP + BAR_HEIGHT + 24.0
	var p1 := sim.fighters[0]
	var p2 := sim.fighters[1]
	draw_string(_font, Vector2(BAR_MARGIN, y), _name_text(p1), HORIZONTAL_ALIGNMENT_LEFT, bar_width, 20, P1_COLOR)
	draw_string(_font, Vector2(SCREEN_WIDTH - BAR_MARGIN - bar_width, y), _name_text(p2), HORIZONTAL_ALIGNMENT_RIGHT, bar_width, 20, P2_COLOR)


func _name_text(fighter: Fighter) -> String:
	var label := "P%d  %s" % [fighter.slot + 1, fighter.data.display_name]
	if fighter.slot == 1 and sim.dummy_mode != FightSim.DummyMode.OFF:
		return label + "  (boneco: %s)" % sim.dummy_mode_name()
	if InputRouter.slot_devices[fighter.slot] == InputRouter.DEVICE_NONE:
		return label + "  (aperte um botão)"
	return label


func _draw_combo(attacker_slot: int) -> void:
	var defender := sim.fighters[1 - attacker_slot]
	if defender.combo_hits < 2:
		return
	var text := "%d GOLPES" % defender.combo_hits
	var alignment := HORIZONTAL_ALIGNMENT_LEFT if attacker_slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	draw_string(_font, Vector2(BAR_MARGIN, 150.0), text, alignment, SCREEN_WIDTH - BAR_MARGIN * 2.0, 34, _player_color(attacker_slot))


func _draw_banner() -> void:
	if _banner_frames <= 0:
		return
	var alpha := minf(float(_banner_frames) / BANNER_FADE_FRAMES, 1.0)
	draw_string(_font, Vector2(2, 222.0), _banner_text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 54, Color(0, 0, 0, 0.6 * alpha))
	draw_string(_font, Vector2(0, 220.0), _banner_text, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 54, Color(_banner_color, alpha))


func _draw_center() -> void:
	if center_title != "":
		draw_string(_font, Vector2(0, 300.0), center_title, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 96, Color(1, 1, 1))
	if center_subtitle != "":
		draw_string(_font, Vector2(0, 360.0), center_subtitle, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 28, Color(0.85, 0.85, 1.0))
