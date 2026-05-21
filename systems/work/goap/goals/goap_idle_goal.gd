extends GOAPGoal
class_name GOAPIdleGoal

@export var idle_priority_when_no_task: float = 0.2

func _init() -> void:
	goal_id = &"idle"
	display_name = "Idle"
	desired_state = {
		&"is_idle": true
	}
	base_priority = 0.2

func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.get_fact(&"needs_rest", false):
		return 0.0

	if blackboard.current_target != null:
		return 0.0

	return idle_priority_when_no_task
