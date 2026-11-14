class_name CharacterData
extends Resource

var id: String = "generic"
var display_name: String = "Lutador"
var health: int = 1000
var walk_speed: float = 5.5
var back_speed: float = 4.5
var jump_velocity: float = -17.0
var jump_forward_speed: float = 6.5
var jump_back_speed: float = 5.5
var gravity: float = 0.85
var dash_speed: float = 14.0
var dash_frames: int = 10
var backdash_speed: float = 11.0
var backdash_frames: int = 14
var backdash_invuln_frames: int = 7
var stand_hurtbox: Rect2 = Rect2(-28, -170, 56, 170)
var crouch_hurtbox: Rect2 = Rect2(-34, -130, 68, 130)
var air_hurtbox: Rect2 = Rect2(-26, -150, 52, 130)
var stand_pushbox: Rect2 = Rect2(-34, -150, 68, 150)
var crouch_pushbox: Rect2 = Rect2(-34, -105, 68, 105)
var air_pushbox: Rect2 = Rect2(-22, -140, 44, 90)
var moves: Array[MoveData] = []
var accent_color: Color = Color(0.9, 0.9, 1.0)
var rig: Dictionary = {}
var animations: Dictionary = {}
var intro_line: String = ""
var win_line: String = ""


func find_move(button: ButtonMap.Action, stance: MoveData.Stance) -> MoveData:
	for move in moves:
		if move.button == button and move.stance == stance:
			return move
	return null


func move_by_id(move_id: String) -> MoveData:
	for move in moves:
		if move.id == move_id:
			return move
	return null
