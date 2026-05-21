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

var blackboard: WorkerBlackboard
var planner := GOAPPlanner.new()
var current_plan: GOAPPlan = null
var current_goal: GOAPGoal = null
var current_action: GOAPAction = null
var replan_timer: float = 0.0

func _ready() -> void:
	blackboard = get_node_or_null(blackboard_path) as WorkerBlackboard
	if blackboard == null:
		push_error("GOAPBrain missing blackboard_path.")
		return

	_request_replan()

func _process(delta: float) -> void:
	if blackboard == null:
		return

	replan_timer -= delta
	if replan_timer <= 0.0:
		replan_timer = replan_interval
		if _should_replan():
			_request_replan()

	_tick_current_action(delta)

func _tick_current_action(delta: float) -> void:
	if current_plan == null or current_plan.is_complete():
		_request_replan()
		return

	if current_action == null:
		current_action = current_plan.get_current_action()
		if current_action == null:
			_request_replan()
			return
		current_action.enter(blackboard)
		action_started.emit(current_action)

	var result := current_action.tick(blackboard, delta)

	match result:
		GOAPAction.ActionStatus.SUCCEEDED:
			current_action.exit(blackboard)
			action_finished.emit(current_action)
			current_plan.advance()
			current_action = null

			if current_plan.is_complete():
				_request_replan()

		GOAPAction.ActionStatus.FAILED:
			current_action.exit(blackboard)
			action_failed.emit(current_action)
			current_action = null
			_request_replan()

		GOAPAction.ActionStatus.RUNNING:
			pass

		_:
			pass

func _should_replan() -> bool:
	if current_plan == null:
		return true
	if current_goal == null:
		return true
	if current_action != null and not current_action.interruptible:
		return false
	if current_goal.is_satisfied(blackboard.world_state):
		return true

	var best_goal := _select_best_goal()
	return allow_interrupt and best_goal != null and best_goal != current_goal

func _request_replan() -> void:
	if current_action != null:
		current_action.exit(blackboard)
		current_action = null

	var best_goal := _select_best_goal()
	if best_goal == null:
		current_plan = null
		current_goal = null
		return

	var plan := planner.build_plan(
		blackboard.world_state,
		best_goal,
		available_actions,
		blackboard
	)

	current_goal = best_goal
	current_plan = plan

	goal_changed.emit(current_goal)
	plan_changed.emit(current_plan)

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
