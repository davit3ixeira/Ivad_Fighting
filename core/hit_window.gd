class_name HitWindow
extends Resource

var start: int = 1
var end: int = 1
var hitboxes: Array[Rect2] = []
var overrides: Dictionary = {}


static func create(start_frame: int, end_frame: int, rects: Array, hit_overrides: Dictionary = {}) -> HitWindow:
	var window := HitWindow.new()
	window.start = start_frame
	window.end = end_frame
	window.hitboxes.assign(rects)
	window.overrides = hit_overrides
	return window
