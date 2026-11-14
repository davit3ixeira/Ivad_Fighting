class_name MenuOverlay
extends Control

const DIM_COLOR := Color(0, 0, 0.03, 0.62)
const TITLE_Y := 250.0
const SUBTITLE_Y := 304.0
const QUOTE_Y := 350.0
const ITEM_TOP := 400.0
const ITEM_SIZE := Vector2(480, 48)
const ITEM_GAP := 62.0

var title: String = ""
var title_color: Color = Color.WHITE
var subtitle: String = ""
var quote: String = ""
var items: Array[String] = []
var index: int = 0
var top_offset: float = 0.0
var dim_alpha: float = DIM_COLOR.a

var _clock: int = 0


func _ready() -> void:
	UiKit.fill_screen(self)
	visible = false


func open(new_title: String, color: Color, new_subtitle: String, new_quote: String, new_items: Array[String]) -> void:
	title = new_title
	title_color = color
	subtitle = new_subtitle
	quote = new_quote
	items = new_items
	index = 0
	_clock = 0
	visible = true
	queue_redraw()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func move(step: int) -> void:
	if items.is_empty():
		return
	index = wrapi(index + step, 0, items.size())
	AudioManager.play_sfx("menu_move")
	queue_redraw()


func refresh() -> void:
	if not visible:
		return
	_clock += 1
	queue_redraw()


func _draw() -> void:
	var appear := minf(_clock / 10.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, UiKit.SCREEN_SIZE), Color(DIM_COLOR, dim_alpha * appear))
	UiKit.centered(self, TITLE_Y + top_offset, title, 72, title_color)
	if subtitle != "":
		UiKit.centered(self, SUBTITLE_Y + top_offset, subtitle, 30, UiKit.TEXT_COLOR)
	if quote != "":
		UiKit.centered(self, QUOTE_Y + top_offset, "“%s”" % quote, 20, UiKit.DIM_TEXT_COLOR, false)
	for item_index in items.size():
		var rect := Rect2(Vector2((UiKit.SCREEN_SIZE.x - ITEM_SIZE.x) * 0.5, ITEM_TOP + top_offset + item_index * ITEM_GAP), ITEM_SIZE)
		var selected := item_index == index
		if selected:
			UiKit.panel(self, rect.grow(3.0), Color.WHITE, Color(title_color, 0.25), 3.0)
		else:
			UiKit.panel(self, rect, Color(title_color, 0.35))
		var color := UiKit.TEXT_COLOR if selected else UiKit.DIM_TEXT_COLOR
		UiKit.text(self, Vector2(rect.position.x, rect.position.y + 33.0), items[item_index], 24, color, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER, selected)
	UiKit.hint(self)
