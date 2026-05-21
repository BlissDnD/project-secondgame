extends GOAPGoal
class_name GOAPDeliverItemGoal

@export var deliver_priority: float = 8.0

func _init() -> void:
	goal_id = &"deliver_item"
	display_name = "Deliver Item"
	desired_state = {
		&"item_delivered": true
	}
	base_priority = 8.0

func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	if blackboard == null:
		return false

	return blackboard.carried_item != null and blackboard.current_target != null

func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.get_fact(&"needs_rest", false):
		return 0.0

	if blackboard.carried_item == null:
		return 0.0

	if blackboard.current_target == null:
		return 0.0

	return deliver_priority
