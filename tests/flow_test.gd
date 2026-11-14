extends Node

const RUNNER_SCRIPT := "res://tests/flow_runner.gd"


func _ready() -> void:
	var runner := Node.new()
	runner.set_script(load(RUNNER_SCRIPT))
	get_tree().root.add_child.call_deferred(runner)
	GameFlow.go_to(GameFlow.PRESS_START)
