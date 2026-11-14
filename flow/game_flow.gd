extends Node

const PRESS_START := "res://scenes/press_start.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const CHARACTER_SELECT := "res://scenes/character_select.tscn"
const STAGE_SELECT := "res://scenes/stage_select.tscn"
const FIGHT := "res://scenes/fight.tscn"
const FADE_FRAMES := 12
const FADE_LAYER := 100

var characters: Array[int] = [0, 0]
var stage: int = 0

var _fade_rect: ColorRect
var _target: String = ""
var _fade_out_left: int = 0
var _fade_in_left: int = 0


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = FADE_LAYER
	add_child(layer)
	_fade_rect = ColorRect.new()
	UiKit.fill_screen(_fade_rect)
	_fade_rect.color = Color(0, 0, 0, 0)
	layer.add_child(_fade_rect)


func go_to(scene_path: String) -> void:
	if _target != "":
		return
	_target = scene_path
	_fade_out_left = FADE_FRAMES


func is_transitioning() -> bool:
	return _target != ""


func quit_game() -> void:
	get_tree().quit()


func _physics_process(_delta: float) -> void:
	if _fade_out_left > 0:
		_fade_out_left -= 1
		_fade_rect.color.a = 1.0 - float(_fade_out_left) / FADE_FRAMES
		if _fade_out_left == 0:
			get_tree().change_scene_to_file(_target)
			_target = ""
			_fade_in_left = FADE_FRAMES
	elif _fade_in_left > 0:
		_fade_in_left -= 1
		_fade_rect.color.a = float(_fade_in_left) / FADE_FRAMES
