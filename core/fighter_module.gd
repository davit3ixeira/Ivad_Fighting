class_name FighterModule
extends RefCounted


func on_setup(_fighter: Fighter) -> void:
	pass


func on_frame(_fighter: Fighter, _sim: FightSim) -> void:
	pass


func can_start_move(_fighter: Fighter, _move: MoveData) -> bool:
	return true


func resolve_move(_fighter: Fighter, move: MoveData) -> MoveData:
	return move


func on_move_started(_fighter: Fighter, _move: MoveData) -> void:
	pass


func on_move_event(_fighter: Fighter, _sim: FightSim, _event: Dictionary) -> void:
	pass


func modify_hit(_fighter: Fighter, _hit: HitInfo) -> void:
	pass


func on_hit_dealt(_fighter: Fighter, _defender: Fighter, _hit: HitInfo, _blocked: bool, _sim: FightSim) -> void:
	pass


func on_damage_taken(_fighter: Fighter, _hit: HitInfo, _damage: int) -> void:
	pass


func on_interrupted(_fighter: Fighter) -> void:
	pass


func hud_gauges(_fighter: Fighter) -> Array[Dictionary]:
	return []


func absorb_hit(_fighter: Fighter, _hit: HitInfo) -> bool:
	return false


func visual_flags(_fighter: Fighter) -> Dictionary:
	return {}
