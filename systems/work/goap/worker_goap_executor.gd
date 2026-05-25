extends Node
class_name WorkerGOAPExecutor

signal action_started(action: GOAPAction)
signal action_finished(action: GOAPAction, status: GOAPAction.ActionStatus, reason: String)

@export var blackboard_path: NodePath = NodePath("../WorkerBlackboard")

var blackboard: WorkerBlackboard
var current_action: GOAPAction = null


func _ready() -> void:
	blackboard = get_node_or_null(blackboard_path) as WorkerBlackboard

	if blackboard == null:
		push_error("WorkerGOAPExecutor missing WorkerBlackboard.")


func start_action(action: GOAPAction) -> void:
	if action == null:
		return

	if blackboard == null:
		push_error("WorkerGOAPExecutor cannot start action without blackboard.")
		return

	if current_action != null:
		interrupt_current_action("replaced_by_new_action")

	current_action = action
	current_action.enter(blackboard)
	action_started.emit(current_action)


func tick(delta: float) -> void:
	if current_action == null:
		return

	if blackboard == null:
		_finish_current_action(GOAPAction.ActionStatus.FAILED, "missing_blackboard")
		return

	var result := current_action.tick(blackboard, delta)

	match result:
		GOAPAction.ActionStatus.SUCCEEDED:
			_finish_current_action(result, "")

		GOAPAction.ActionStatus.FAILED:
			_finish_current_action(result, current_action.last_failure_reason)

		GOAPAction.ActionStatus.INTERRUPTED:
			_finish_current_action(result, current_action.last_failure_reason)

		GOAPAction.ActionStatus.RUNNING:
			pass

		_:
			pass


func interrupt_current_action(reason: String = "interrupted") -> void:
	if current_action == null:
		return

	current_action.interrupt(blackboard, reason)
	_finish_current_action(current_action.status, reason)


func has_action() -> bool:
	return current_action != null


func get_current_action_id() -> StringName:
	if current_action == null:
		return &"None"

	return current_action.action_id


func _finish_current_action(status: GOAPAction.ActionStatus, reason: String = "") -> void:
	if current_action == null:
		return

	var finished_action := current_action

	finished_action.exit(blackboard)
	current_action = null

	action_finished.emit(finished_action, status, reason)
