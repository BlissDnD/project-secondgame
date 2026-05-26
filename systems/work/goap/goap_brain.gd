extends Node
class_name GOAPBrain

signal plan_changed(plan: GOAPPlan)
signal goal_changed(goal: GOAPGoal)
signal action_started(action: GOAPAction)
signal action_finished(action: GOAPAction)
signal action_failed(action: GOAPAction)

@export var blackboard_path: NodePath
@export var available_actions: Array[GOAPAction] = []
@export var goals: Array[GOAPGoal] = []
@export var replan_interval: float = 0.5
@export var allow_interrupt: bool = true
@export var debug_enabled: bool = true

var blackboard: WorkerBlackboard
var planner := GOAPPlanner.new()

var current_plan: GOAPPlan = null
var current_goal: GOAPGoal = null
var current_action: GOAPAction = null

var replan_timer: float = 0.0
var is_replanning: bool = false


func _ready() -> void:
	blackboard = get_node_or_null(blackboard_path) as WorkerBlackboard

	if blackboard == null:
		push_error("GOAPBrain missing blackboard_path.")
		return

	_refresh_blackboard()
	_request_replan("ready")


func _process(delta: float) -> void:
	if blackboard == null:
		return

	_refresh_blackboard()

	replan_timer -= delta

	if replan_timer <= 0.0:
		replan_timer = replan_interval

		if _should_replan():
			_request_replan("periodic")

	_tick_current_action(delta)


func _refresh_blackboard() -> void:
	if blackboard != null and blackboard.has_method("update_world_state"):
		blackboard.update_world_state()


func _tick_current_action(delta: float) -> void:
	if is_replanning:
		return

	if current_plan == null:
		return

	if current_plan.is_complete():
		_request_replan("plan_complete")
		return

	if current_action == null:
		current_action = current_plan.get_current_action()

		if current_action == null:
			_request_replan("missing_current_action")
			return

		if not current_action.is_valid_for(blackboard):
			_finish_action_as_failed(current_action, "action_not_valid")
			_request_replan("invalid_action")
			return

		current_action.enter(blackboard)

		if debug_enabled:
			print("[GOAP] action started: ", current_action.action_id)

		action_started.emit(current_action)

	var result := current_action.tick(blackboard, delta)

	match result:
		GOAPAction.ActionStatus.SUCCEEDED:
			_finish_action_success()

		GOAPAction.ActionStatus.FAILED:
			_finish_action_failed(current_action.last_failure_reason)

		GOAPAction.ActionStatus.INTERRUPTED:
			_finish_action_failed(current_action.last_failure_reason)

		GOAPAction.ActionStatus.RUNNING:
			pass

		_:
			pass


func _finish_action_success() -> void:
	if current_action == null:
		return

	var finished_action := current_action

	finished_action.exit(blackboard)

	if debug_enabled:
		print("[GOAP] action finished: ", finished_action.action_id)

	action_finished.emit(finished_action)

	if current_plan != null:
		current_plan.advance()

	current_action = null

	if current_plan == null or current_plan.is_complete():
		_request_replan("action_success_plan_complete")


func _finish_action_failed(reason: String = "") -> void:
	if current_action == null:
		return

	var failed_action := current_action

	failed_action.exit(blackboard)

	if debug_enabled:
		print("[GOAP] action failed: ", failed_action.action_id, " reason=", reason)

	action_failed.emit(failed_action)

	current_action = null
	_request_replan("action_failed")


func _finish_action_as_failed(action: GOAPAction, reason: String) -> void:
	if action == null:
		return

	action.fail(reason)

	if debug_enabled:
		print("[GOAP] action rejected: ", action.action_id, " reason=", reason)

	action_failed.emit(action)


func _should_replan() -> bool:
	if is_replanning:
		return false

	if current_plan == null:
		return true

	if current_goal == null:
		return true

	if current_action != null and not current_action.interruptible:
		return false

	_refresh_blackboard()

	if current_goal.is_satisfied(blackboard.world_state):
		return true

	var best_goal := _select_best_goal()

	if best_goal == null:
		return false

	return allow_interrupt and best_goal != current_goal


func _request_replan(reason: String = "manual") -> void:
	if is_replanning:
		return

	is_replanning = true
	_refresh_blackboard()

	if debug_enabled:
		print("[GOAP] replan requested: ", reason)

	if current_action != null:
		if current_action.interruptible:
			current_action.interrupt(blackboard, "replan_" + reason)
		current_action.exit(blackboard)
		current_action = null

	var best_goal := _select_best_goal()

	if best_goal == null:
		current_plan = null
		current_goal = null

		if debug_enabled:
			print("[GOAP] no valid goal")

		is_replanning = false
		return

	var plan := planner.build_plan(
		blackboard.world_state,
		best_goal,
		available_actions,
		blackboard
	)

	current_goal = best_goal
	current_plan = plan

	if debug_enabled:
		if current_plan == null:
			print("[GOAP] no plan for goal: ", current_goal.goal_id)
		else:
			print("[GOAP] plan selected for goal: ", current_goal.goal_id)

	goal_changed.emit(current_goal)
	plan_changed.emit(current_plan)

	is_replanning = false


func _select_best_goal() -> GOAPGoal:
	var best_goal: GOAPGoal = null
	var best_priority := -INF

	for goal: GOAPGoal in goals:
		if goal == null:
			continue

		if not goal.is_valid_for(blackboard):
			continue

		var priority := goal.get_priority(blackboard)

		if priority < goal.min_priority_to_run:
			continue

		if priority > best_priority:
			best_priority = priority
			best_goal = goal

	return best_goal


func get_debug_state() -> Dictionary:
	return {
		"current_goal": str(current_goal.goal_id) if current_goal != null else "None",
		"current_action": str(current_action.action_id) if current_action != null else "None",
		"has_plan": current_plan != null,
		"plan_complete": current_plan.is_complete() if current_plan != null else true,
		"available_actions": available_actions.size(),
		"goals": goals.size()
	}
