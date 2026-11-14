class_name BurstEffect
extends Node2D

const FLASH_PORTION := 0.35

var _config: Dictionary = {}
var _color: Color = Color.WHITE
var _frame: int = 0


func setup(config: Dictionary, params: Dictionary) -> void:
	_config = config
	_color = params.get("color", Color.WHITE)
	material = DrawKit.additive_material()


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _frame >= _config.get("lifetime", 20):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var lifetime: float = _config.get("lifetime", 20)
	var t := _frame / lifetime
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var fade := 1.0 - t
	var radius: float = lerpf(_config.get("start_radius", 10.0), _config.get("radius", 120.0), eased)
	var width: float = _config.get("ring_width", 4.0)
	DrawKit.ring(self, Vector2.ZERO, radius, Color(_color, fade), width * fade + 1.0, 40)
	if _config.get("inner_ring", false):
		DrawKit.ring(self, Vector2.ZERO, radius * 0.62, Color(1, 1, 1, fade * 0.7), width * 0.6 * fade + 1.0, 32)
	var star_count: int = _config.get("stars", 0)
	var star_size: float = _config.get("star_size", 8.0)
	var spin: float = _config.get("spin", 0.8)
	for index in star_count:
		var angle := TAU * index / star_count + t * spin
		var point := Vector2(cos(angle), sin(angle)) * radius
		var paint := Color(1, 1, 1, fade) if index % 2 == 0 else Color(_color, fade)
		DrawKit.star(self, point, star_size * (0.4 + fade), paint, angle)
	var ray_count: int = _config.get("rays", 0)
	var ray_length: float = _config.get("ray_length", 80.0)
	for index in ray_count:
		var angle := TAU * (index + 0.5) / ray_count
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(dir * radius * 0.35, dir * (radius * 0.35 + ray_length * eased), Color(_color, fade * 0.7), 3.0 * fade + 1.0)
	var flash_radius: float = _config.get("flash", 0.0)
	if flash_radius > 0.0 and t < FLASH_PORTION:
		var flash_fade := 1.0 - t / FLASH_PORTION
		DrawKit.disc(self, Vector2.ZERO, flash_radius * (0.5 + 0.5 * t / FLASH_PORTION), Color(1, 1, 1, 0.85 * flash_fade))
