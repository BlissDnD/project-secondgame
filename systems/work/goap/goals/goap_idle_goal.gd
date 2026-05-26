extends GOAPGoal
class_name GOAPIdleGoal

@export var idle_priority_when_no_task: float = 0.2


func _init() -> void:
	goal_id = &"idle_goal"
	display_name = "Idle Goal"

	desired_state = {
		&"is_wandering": true
	}

	base_priority = 0.2


func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.has_low_stamina():
		return 0.0

	if blackboard.has_assignment():
		return 0.0

	if blackboard.has_valid_target():
		return 0.0

	return idle_priority_when_no_task
