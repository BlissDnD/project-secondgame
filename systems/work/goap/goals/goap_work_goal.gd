extends GOAPGoal
class_name GOAPWorkGoal

@export var work_priority: float = 5.0


func _init() -> void:
	goal_id = &"work_goal"
	display_name = "Work Goal"

	desired_state = {
		&"has_cargo": true
	}

	base_priority = 5.0
	min_priority_to_run = 0.1


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.has_assignment() \
		and not blackboard.has_low_stamina()


func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.has_low_stamina():
		return 0.0

	if not blackboard.has_assignment():
		return 0.0

	if blackboard.has_cargo():
		return 0.0

	return work_priority
