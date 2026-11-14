class_name HaluhoModule
extends FighterModule

const PACT_EFFECT_HEIGHT := Vector2(0, -120)

var pact_frames_left: int = 0
var true_form: bool = false


func on_setup(_fighter: Fighter) -> void:
	pact_frames_left = 0
	true_form = false


func can_start_move(fighter: Fighter, move: MoveData) -> bool:
	if move.id == "pacto":
		return pact_frames_left <= 0 and fighter.health > int(fighter.data.params["pact_cost"])
	return true


func on_frame(fighter: Fighter, _sim: FightSim) -> void:
	if pact_frames_left > 0:
		pact_frames_left -= 1
	true_form = _in_true_form_move(fighter)


func on_move_started(fighter: Fighter, move: MoveData) -> void:
	if pact_frames_left > 0 and move.armor_hits > 0:
		fighter.armor_hits_left += int(fighter.data.params["pact_extra_armor"])
	true_form = _in_true_form_move(fighter)


func on_move_event(fighter: Fighter, sim: FightSim, event: Dictionary) -> void:
	if event.get("name", "") != "pact":
		return
	var params: Dictionary = fighter.data.params
	fighter.health = maxi(fighter.health - int(params["pact_cost"]), 1)
	pact_frames_left = params["pact_frames"]
	sim.request_effect("pact", fighter.position + PACT_EFFECT_HEIGHT, {"color": fighter.data.power_color})
	sim.request_sfx("haluho_pact")


func modify_hit(fighter: Fighter, hit: HitInfo) -> void:
	var params: Dictionary = fighter.data.params
	var multiplier := 1.0 + float(params["rage_max_bonus"]) * rage_ratio(fighter)
	if pact_frames_left > 0:
		multiplier += float(params["pact_damage_bonus"])
		hit.chip_damage += int(params["pact_chip_bonus"])
		if hit.effect == "":
			hit.effect = "hellfire"
	hit.damage = int(round(hit.damage * multiplier))


func on_interrupted(fighter: Fighter) -> void:
	true_form = false
	fighter.hidden = false


func rage_ratio(fighter: Fighter) -> float:
	return clampf(1.0 - float(fighter.health) / fighter.data.health, 0.0, 1.0)


func hud_gauges(fighter: Fighter) -> Array[Dictionary]:
	var pact_fraction := float(pact_frames_left) / float(fighter.data.params["pact_frames"])
	return [
		{"label": "PACTO", "fraction": pact_fraction, "active": pact_frames_left > 0},
		{"label": "RAIVA", "fraction": rage_ratio(fighter), "active": true},
	]


func visual_flags(fighter: Fighter) -> Dictionary:
	var flags := {}
	var params: Dictionary = fighter.data.params
	if pact_frames_left > 0:
		flags["aura_color"] = params["aura_color"]
		flags["aura_strength"] = minf(float(pact_frames_left) / 30.0, 1.0)
	if true_form:
		flags["form_scale"] = params["true_form_scale"]
		flags["wings"] = true
	return flags


func _in_true_form_move(fighter: Fighter) -> bool:
	if fighter.state != Fighter.State.ATTACK or fighter.current_move == null:
		return false
	return fighter.data.params["true_form_moves"].has(fighter.current_move.id)
