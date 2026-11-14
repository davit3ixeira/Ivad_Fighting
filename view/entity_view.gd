class_name EntityView
extends Node2D

const FADE_FRAMES := 8

var entity: Entity
var player_color: Color = Color.WHITE
var power_color: Color = Color.WHITE
var age: int = 0

var _fade_left: int = -1
var _glow: DrawLayer


func setup(target: Entity, owner_color: Color) -> void:
	entity = target
	player_color = owner_color
	power_color = target.owner.data.power_color
	_glow = DrawLayer.new()
	_glow.material = DrawKit.additive_material()
	_glow.painter = draw_glow
	add_child(_glow)
	position = entity.position
	scale.x = entity.facing


func sync() -> void:
	age += 1
	if _fade_left < 0:
		position = entity.position
		scale.x = entity.facing
	else:
		_fade_left -= 1
		if _fade_left <= 0:
			queue_free()
			return
	queue_redraw()
	_glow.queue_redraw()


func finish(_reason: String) -> void:
	if _fade_left < 0:
		_fade_left = FADE_FRAMES


func is_finished() -> bool:
	return _fade_left == 0


func fade() -> float:
	if _fade_left < 0:
		return minf(age / 6.0, 1.0)
	return float(_fade_left) / FADE_FRAMES


func _draw() -> void:
	draw_solid(self)


func draw_solid(_canvas: CanvasItem) -> void:
	pass


func draw_glow(_canvas: CanvasItem) -> void:
	pass
