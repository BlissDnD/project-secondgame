extends Node
class_name UtilityGoalSelector

signal goal_changed(old_goal: StringName, new_goal: StringName)

const NONE: StringName = &"None"

const REST_GOAL: StringName = &"RestGoal"
const WORK_GOAL: StringName = &"WorkGoal"
const IDLE_GOAL: StringName = &"IdleGoal"
const FAILED_GOAL: StringName = &"FailedGoal"

var current_goal: StringName = NONE
var previous_goal: StringName = NONE


func select_goal(current_need: StringName) -> StringName:
	var next_goal := _goal_from_need(current_need)
	_set_goal(next_goal)
	return current_goal


func _goal_from_need(need: StringName) -> StringName:
	match need:
		WorkerNeedSystem.RECOVER_STAMINA_NEED:
			return REST_GOAL

		WorkerNeedSystem.DO_ASSIGNED_WORK_NEED:
			return WORK_GOAL

		WorkerNeedSystem.IDLE_NEED:
			return IDLE_GOAL

		WorkerNeedSystem.FAILED_NEED:
			return FAILED_GOAL

		_:
			return IDLE_GOAL


func _set_goal(new_goal: StringName) -> void:
	if current_goal == new_goal:
		return

	var old_goal := current_goal
	previous_goal = current_goal
	current_goal = new_goal

	goal_changed.emit(old_goal, current_goal)


func is_rest_goal() -> bool:
	return current_goal == REST_GOAL


func is_work_goal() -> bool:
	return current_goal == WORK_GOAL


func is_idle_goal() -> bool:
	return current_goal == IDLE_GOAL


func is_failed_goal() -> bool:
	return current_goal == FAILED_GOAL


func get_debug_state() -> Dictionary:
	return {
		"current_goal": str(current_goal),
		"previous_goal": str(previous_goal)
	}
