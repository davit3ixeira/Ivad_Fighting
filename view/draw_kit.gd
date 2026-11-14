class_name DrawKit
extends RefCounted

const TEXTURE_SIZE := 64
const DISC_EDGE := 1.5
const DISC_FILL_RATIO := 0.96
const STAR_THICKNESS_RATIO := 0.3
const RING_SEGMENTS := 24

static var _disc: ImageTexture
static var _soft: ImageTexture


static func additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


static func disc_texture() -> ImageTexture:
	if _disc == null:
		_disc = _build_radial_texture(false)
	return _disc


static func soft_texture() -> ImageTexture:
	if _soft == null:
		_soft = _build_radial_texture(true)
	return _soft


static func _build_radial_texture(soft: bool) -> ImageTexture:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(TEXTURE_SIZE, TEXTURE_SIZE) * 0.5
	var radius := TEXTURE_SIZE * 0.5 * DISC_FILL_RATIO
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha := 0.0
			if soft:
				var falloff := clampf(1.0 - distance / radius, 0.0, 1.0)
				alpha = falloff * falloff
			else:
				alpha = clampf((radius - distance) / DISC_EDGE, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


static func disc(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.3:
		return
	var half := radius / DISC_FILL_RATIO
	canvas.draw_texture_rect(disc_texture(), Rect2(center.x - half, center.y - half, half * 2.0, half * 2.0), false, color)


static func soft_disc(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.3:
		return
	canvas.draw_texture_rect(soft_texture(), Rect2(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0), false, color)


static func capsule(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	canvas.draw_line(from, to, color, width)
	disc(canvas, from, width * 0.5, color)
	disc(canvas, to, width * 0.5, color)


static func quad(canvas: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	canvas.draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([color, color, color, color]), PackedVector2Array())


static func diamond(canvas: CanvasItem, center: Vector2, half_width: float, half_height: float, color: Color) -> void:
	quad(canvas, center + Vector2(0, -half_height), center + Vector2(half_width, 0), center + Vector2(0, half_height), center + Vector2(-half_width, 0), color)


static func star(canvas: CanvasItem, center: Vector2, radius: float, color: Color, rotation: float = 0.0) -> void:
	if radius < 0.6:
		return
	var axis := Vector2(cos(rotation), sin(rotation))
	var normal := Vector2(-axis.y, axis.x)
	var thin := radius * STAR_THICKNESS_RATIO
	quad(canvas, center + axis * radius, center + normal * thin, center - axis * radius, center - normal * thin, color)
	quad(canvas, center + normal * radius, center + axis * thin, center - normal * radius, center - axis * thin, color)


static func glow_circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	soft_disc(canvas, center, radius * 2.4, Color(color, color.a * 0.6))
	disc(canvas, center, radius, color)


static func ring(canvas: CanvasItem, center: Vector2, radius: float, color: Color, width: float, segments: int = RING_SEGMENTS) -> void:
	if radius < 1.0:
		return
	var previous := center + Vector2(radius, 0)
	var glow := Color(color, color.a * 0.3)
	for index in range(1, segments + 1):
		var angle := TAU * index / segments
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		canvas.draw_line(previous, point, glow, width * 2.6)
		canvas.draw_line(previous, point, color, width)
		previous = point


static func ellipse_ring(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float, rotation: float = 0.0, segments: int = RING_SEGMENTS) -> void:
	var previous := center + Vector2(radii.x, 0).rotated(rotation)
	for index in range(1, segments + 1):
		var angle := TAU * index / segments
		var point := center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(rotation)
		canvas.draw_line(previous, point, color, width)
		previous = point
