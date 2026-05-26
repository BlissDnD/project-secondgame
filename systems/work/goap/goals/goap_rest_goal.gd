extends GOAPGoal
class_name GOAPRestGoal

@export var rest_priority: float = 10.0


func _init() -> void:
	goal_id = &"rest_goal"
	display_name = "Rest Goal"

	desired_state = {
		&"stamina_low": false,
		&"can_work": true
	}

	base_priority = 10.0
	min_priority_to_run = 0.1


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null and blackboard.has_low_stamina()


func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.has_low_stamina():
		return rest_priority

	return 0.0
