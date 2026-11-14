class_name DrawLayer
extends Node2D

var painter: Callable


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
