extends RefCounted
class_name GOAPPlan

var goal: GOAPGoal
var actions: Array[GOAPAction] = []
var total_cost: float = 0.0
var cursor: int = 0

func is_empty() -> bool:
	return actions.is_empty()

func get_current_action() -> GOAPAction:
	if cursor < 0 or cursor >= actions.size():
		return null
	return actions[cursor]

func advance() -> void:
	cursor += 1

func is_complete() -> bool:
	return cursor >= actions.size()

func reset() -> void:
	cursor = 0
