extends GOAPGoal
class_name GOAPRestGoal

@export var tired_priority: float = 10.0
@export var exhausted_priority: float = 100.0

func _init() -> void:
	goal_id = &"rest"
	display_name = "Rest"
	desired_state = {
		&"needs_rest": false
	}
	base_priority = 10.0

func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null and blackboard.stats != null

func get_priority(blackboard: WorkerBlackboard) -> float:
	if blackboard == null or blackboard.stats == null:
		return 0.0

	if blackboard.stats.is_exhausted():
		return exhausted_priority

	if blackboard.stats.needs_rest():
		return tired_priority

	return 0.0
