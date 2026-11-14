class_name IvadModule
extends FighterModule

const RIFT_HEIGHT := Vector2(0, -92)

var mark: Entity
var well: Entity
var singularity: Entity


func can_start_move(_fighter: Fighter, move: MoveData) -> bool:
	if move.id == "poco_l" or move.id == "poco_h":
		return well == null or not well.alive
	return true


func on_frame(_fighter: Fighter, _sim: FightSim) -> void:
	if mark != null and not mark.alive:
		mark = null
	if well != null and not well.alive:
		well = null
	if singularity != null and not singularity.alive:
		singularity = null


func on_move_event(fighter: Fighter, sim: FightSim, event: Dictionary) -> void:
	match event.get("name", ""):
		"plant_mark":
			_plant_mark(fighter, sim)
		"cast_well":
			well = sim.spawn_entity_by_id(fighter, event["entity"], fighter.data.params["well_spawn_offset"])
			sim.request_sfx("ivad_well")
		"teleport_out":
			fighter.hidden = true
			sim.request_effect("rift", fighter.position + RIFT_HEIGHT, _effect_params(fighter))
			sim.request_sfx("ivad_teleport")
		"teleport_in":
			_teleport_in(fighter, sim, event.get("target", "behind"))
		"open_singularity":
			_open_singularity(fighter, sim)


func _plant_mark(fighter: Fighter, sim: FightSim) -> void:
	if mark != null and mark.alive:
		sim.remove_entity(mark, "replaced")
	mark = sim.spawn_entity_by_id(fighter, "cosmic_mark", Vector2.ZERO)
	mark.position.y = GlobalTuning.FLOOR_Y
	sim.request_effect("mark_plant", mark.position, _effect_params(fighter))
	sim.request_sfx("ivad_mark")


func _teleport_in(fighter: Fighter, sim: FightSim, target: String) -> void:
	var params: Dictionary = fighter.data.params
	var destination := fighter.position.x
	if target == "mark" and mark != null and mark.alive:
		destination = mark.position.x
		sim.remove_entity(mark, "used")
		mark = null
	elif target == "mark":
		destination = fighter.position.x - fighter.facing * params["teleport_retreat_distance"]
	elif fighter.opponent != null:
		destination = fighter.opponent.position.x + fighter.facing * params["teleport_behind_distance"]
	fighter.position = Vector2(destination, GlobalTuning.FLOOR_Y)
	fighter.velocity = Vector2.ZERO
	fighter.push_velocity = Vector2.ZERO
	fighter.airborne = false
	fighter.clamp_to_stage()
	fighter.face_opponent()
	fighter.hidden = false
	sim.request_effect("rift", fighter.position + RIFT_HEIGHT, _effect_params(fighter))


func _open_singularity(fighter: Fighter, sim: FightSim) -> void:
	var params: Dictionary = fighter.data.params
	var distance: float = params["singularity_max_distance"]
	if fighter.opponent != null:
		distance = (fighter.opponent.position.x - fighter.position.x) * fighter.facing
	distance = clampf(distance, params["singularity_min_distance"], params["singularity_max_distance"])
	var limit := GlobalTuning.STAGE_HALF_WIDTH - 40.0
	var x := clampf(fighter.position.x + fighter.facing * distance, -limit, limit)
	var spawn_position := Vector2(x, GlobalTuning.FLOOR_Y + params["singularity_height"])
	singularity = sim.spawn_entity(fighter, fighter.data.entities["singularity"], spawn_position, fighter.facing)
	sim.request_sfx("ivad_singularity")


func on_interrupted(fighter: Fighter) -> void:
	fighter.hidden = false


func hud_gauges(_fighter: Fighter) -> Array[Dictionary]:
	var active := mark != null and mark.alive
	var fraction := 0.0
	if active:
		fraction = 1.0 - float(mark.frame) / mark.data.lifetime
	return [{"label": "MARCA", "fraction": fraction, "active": active}]


func _effect_params(fighter: Fighter) -> Dictionary:
	return {"facing": fighter.facing, "color": fighter.data.power_color}
