class_name GravityWellBehavior
extends EntityBehavior


func on_step(entity: Entity, sim: FightSim) -> void:
	var params: Dictionary = entity.data.params
	var radius: float = params["pull_radius"]
	var defender := entity.owner.opponent
	if defender != null:
		var distance := absf(defender.position.x - entity.position.x)
		if distance <= radius:
			var falloff := 1.0 - 0.5 * distance / radius
			sim.apply_pull(defender, entity.position.x, params["pull_strength"] * falloff)
	for other in sim.entities:
		if not other.alive or other.owner == entity.owner or not other.data.cuttable:
			continue
		var toward := entity.position - other.position
		if toward.length() <= radius and toward.length() > 1.0:
			other.velocity += toward.normalized() * params["projectile_bend"]


func on_hit(entity: Entity, _defender: Fighter, _blocked: bool, _sim: FightSim) -> void:
	entity.velocity = Vector2.ZERO


func on_removed(entity: Entity, sim: FightSim, _reason: String) -> void:
	sim.request_effect("well_pop", entity.position, {"color": entity.owner.data.power_color})
