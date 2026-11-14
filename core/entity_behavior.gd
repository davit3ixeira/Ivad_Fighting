class_name EntityBehavior
extends RefCounted


func on_spawn(_entity: Entity, _sim: FightSim) -> void:
	pass


func on_step(_entity: Entity, _sim: FightSim) -> void:
	pass


func on_hit(_entity: Entity, _defender: Fighter, _blocked: bool, _sim: FightSim) -> void:
	pass


func on_removed(_entity: Entity, _sim: FightSim, _reason: String) -> void:
	pass
