extends GOAPGoal
class_name DeliverCarriedItemGoal


func _init() -> void:
	goal_id = &"deliver_carried_item"
	display_name = "Deliver Carried Item"
	base_priority = 10.0
	min_priority_to_run = 0.1

	desired_state = {
		&"has_cargo": false
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	if blackboard == null:
		return false

	if blackboard.carried_item == null:
		return false

	if not is_instance_valid(blackboard.carried_item):
		return false

	return true
