class_name SingularityBehavior
extends EntityBehavior

const CORE_HALF_WIDTH := 70.0
const HOVER_OFFSET := 72.0
const HOVER_SPEED := 4.0


func on_step(entity: Entity, sim: FightSim) -> void:
	var params: Dictionary = entity.data.params
	var defender := entity.owner.opponent
	if entity.frame < params["nova_frame"]:
		if defender != null:
			_pull(entity, defender, sim, params)
		return
	if entity.vars.has("nova"):
		return
	entity.vars["nova"] = true
	entity.hit = HitInfo.from_fields("singularity_nova", params["nova_hit"])
	entity.hit.from_projectile = true
	entity.hitboxes.assign([params["nova_hitbox"]])
	entity.hits_left = 1
	entity.rehit_timer = 0
	sim.request_effect("supernova", entity.position, {"color": entity.owner.data.power_color})
	sim.request_sfx("ivad_supernova")


func _pull(entity: Entity, defender: Fighter, sim: FightSim, params: Dictionary) -> void:
	var distance := absf(defender.position.x - entity.position.x)
	if distance > params["pull_radius"]:
		return
	var caught := distance <= CORE_HALF_WIDTH and (defender.is_stunned() or defender.state == Fighter.State.BLOCK_STAND or defender.state == Fighter.State.BLOCK_CROUCH)
	sim.apply_pull(defender, entity.position.x, params["hold_strength"] if caught else params["pull_strength"])
	if caught and defender.state == Fighter.State.AIR_HITSTUN:
		defender.velocity = Vector2(0.0, -defender.data.gravity)
		defender.position.y = move_toward(defender.position.y, entity.position.y + HOVER_OFFSET, HOVER_SPEED)
