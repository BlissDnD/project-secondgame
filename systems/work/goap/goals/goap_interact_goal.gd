extends GOAPGoal
class_name GOAPInteractGoal

@export var interaction_priority: float = 5.0

func _init() -> void:
	goal_id = &"interact"
	display_name = "Interact"
	desired_state = {
		&"has_interacted": true
	}
	base_priority = 5.0

func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null and blackboard.current_target != null

func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null:
		return 0.0

	if blackboard.get_fact(&"needs_rest", false):
		return 0.0

	if blackboard.current_target == null:
		return 0.0

	return interaction_priority
