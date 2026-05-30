extends GOAPGoal
class_name HaulVisibleCrystalGoal


func _init() -> void:
	goal_id = &"haul_visible_crystal"
	display_name = "Haul Visible Crystal"
	base_priority = 3.0

	desired_state = {
		&"at_visible_item": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.has_visible_item_type(&"crystal") \
		and not blackboard.has_cargo() \
		and not blackboard.has_assignment()
