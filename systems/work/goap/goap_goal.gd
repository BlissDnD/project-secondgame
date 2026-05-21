extends Resource
class_name GOAPGoal

@export var goal_id: StringName
@export var display_name: String = ""
@export var desired_state: Dictionary[StringName, Variant] = {}
@export var base_priority: float = 1.0
@export var min_priority_to_run: float = 0.1

func is_valid_for(_blackboard: WorkerBlackboard) -> bool:
	return true

func get_priority(_blackboard: WorkerBlackboard) -> float:
	return base_priority

func is_satisfied(state: GOAPWorldState) -> bool:
	return state.matches(desired_state)
