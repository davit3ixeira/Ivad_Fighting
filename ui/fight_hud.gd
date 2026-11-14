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
const BAR_MARGIN := 60.0
const BAR_GAP := 100.0
const BAR_TOP := 38.0
const BAR_HEIGHT := 22.0
const METER_WIDTH := 300.0
const METER_TOP := 672.0
const METER_HEIGHT := 12.0
const GHOST_SPEED := 4.0
const GHOST_DELAY_FRAMES := 30

var sim: FightSim
var center_title: String = ""
var center_subtitle: String = ""

var _ghost: Array[float] = [0.0, 0.0]
var _ghost_hold: Array[int] = [0, 0]
var _last_health: Array[int] = [0, 0]
var _font: Font


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


func refresh() -> void:
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
	var bar_width := (SCREEN_WIDTH - BAR_MARGIN * 2.0 - BAR_GAP) * 0.5
	_draw_health(0, Rect2(BAR_MARGIN, BAR_TOP, bar_width, BAR_HEIGHT), true)
	_draw_health(1, Rect2(SCREEN_WIDTH - BAR_MARGIN - bar_width, BAR_TOP, bar_width, BAR_HEIGHT), false)
	_draw_meter(0, Rect2(BAR_MARGIN, METER_TOP, METER_WIDTH, METER_HEIGHT), false)
	_draw_meter(1, Rect2(SCREEN_WIDTH - BAR_MARGIN - METER_WIDTH, METER_TOP, METER_WIDTH, METER_HEIGHT), true)
	_draw_names(bar_width)
	_draw_combo(0)
	_draw_combo(1)
	_draw_center()


func _draw_health(slot: int, rect: Rect2, anchored_right: bool) -> void:
	var fighter := sim.fighters[slot]
	var color := P1_COLOR if slot == 0 else P2_COLOR
	var max_health := float(fighter.data.health)
	draw_rect(rect.grow(5.0), Color(color, 0.12))
	draw_rect(rect, BACK_COLOR)
	_draw_fill(rect, _ghost[slot] / max_health, anchored_right, GHOST_COLOR)
	_draw_fill(rect, fighter.health / max_health, anchored_right, HEALTH_COLOR)
	draw_rect(rect, color, false, 2.0)


func _draw_meter(slot: int, rect: Rect2, anchored_right: bool) -> void:
	var fighter := sim.fighters[slot]
	var color := P1_COLOR if slot == 0 else P2_COLOR
	var fraction := float(fighter.meter) / GlobalTuning.METER_MAX
	draw_rect(rect.grow(4.0), Color(color, 0.1))
	draw_rect(rect, BACK_COLOR)
	_draw_fill(rect, fraction, anchored_right, METER_FULL_COLOR if fraction >= 1.0 else METER_COLOR)
	draw_rect(rect, color, false, 1.5)


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
	var color := P1_COLOR if attacker_slot == 0 else P2_COLOR
	var text := "%d GOLPES" % defender.combo_hits
	var alignment := HORIZONTAL_ALIGNMENT_LEFT if attacker_slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	draw_string(_font, Vector2(BAR_MARGIN, 150.0), text, alignment, SCREEN_WIDTH - BAR_MARGIN * 2.0, 34, color)


func _draw_center() -> void:
	if center_title != "":
		draw_string(_font, Vector2(0, 300.0), center_title, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 96, Color(1, 1, 1))
	if center_subtitle != "":
		draw_string(_font, Vector2(0, 360.0), center_subtitle, HORIZONTAL_ALIGNMENT_CENTER, SCREEN_WIDTH, 28, Color(0.85, 0.85, 1.0))
