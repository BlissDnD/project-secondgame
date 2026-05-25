extends Resource
class_name GOAPAction

enum ActionStatus {
	READY,
	RUNNING,
	SUCCEEDED,
	FAILED,
	INTERRUPTED
}

@export var action_id: StringName
@export var display_name: String = ""
@export var base_cost: float = 1.0
@export var preconditions: Dictionary[StringName, Variant] = {}
@export var effects: Dictionary[StringName, Variant] = {}
@export var interruptible: bool = true
@export var requires_target: bool = false

var status: ActionStatus = ActionStatus.READY
var last_failure_reason: String = ""
var started: bool = false


func is_valid_for(_blackboard: WorkerBlackboard) -> bool:
	return true


func get_cost(blackboard: WorkerBlackboard) -> float:
	var cost := base_cost

	if requires_target and blackboard.current_target == null:
		cost += 9999.0

	return cost


func are_preconditions_met(state: GOAPWorldState) -> bool:
	return state.matches(preconditions)


func apply_effects_to(state: GOAPWorldState) -> GOAPWorldState:
	var next_state := state.duplicate_state()
	next_state.apply_effects(effects)
	return next_state


func enter(_blackboard: WorkerBlackboard) -> void:
	status = ActionStatus.RUNNING
	last_failure_reason = ""
	started = true


func tick(_blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	status = ActionStatus.SUCCEEDED
	return status


func exit(_blackboard: WorkerBlackboard) -> void:
	status = ActionStatus.READY
	started = false


func fail(reason: String = "failed") -> ActionStatus:
	last_failure_reason = reason
	status = ActionStatus.FAILED
	return status


func interrupt(_blackboard: WorkerBlackboard, reason: String = "interrupted") -> ActionStatus:
	if not interruptible:
		return status

	last_failure_reason = reason
	status = ActionStatus.INTERRUPTED
	return status


func is_running() -> bool:
	return status == ActionStatus.RUNNING


func has_failed() -> bool:
	return status == ActionStatus.FAILED or status == ActionStatus.INTERRUPTED


func has_succeeded() -> bool:
	return status == ActionStatus.SUCCEEDED


func reset() -> void:
	status = ActionStatus.READY
	last_failure_reason = ""
	started = false
