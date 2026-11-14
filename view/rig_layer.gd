class_name RigLayer
extends Node2D

var view: FighterView
var is_halo: bool = false


func _draw() -> void:
	if view == null:
		return
	if is_halo:
		view.draw_halo(self)
	else:
		view.draw_body(self)
