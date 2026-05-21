extends RefCounted
class_name GOAPPlanner

const MAX_EXPANSIONS: int = 256

class PlanNode:
	var state: GOAPWorldState
	var parent: PlanNode
	var action: GOAPAction
	var cost: float = 0.0

	func _init(p_state: GOAPWorldState, p_parent: PlanNode, p_action: GOAPAction, p_cost: float) -> void:
		state = p_state
		parent = p_parent
		action = p_action
		cost = p_cost

func build_plan(
	start_state: GOAPWorldState,
	goal: GOAPGoal,
	actions: Array[GOAPAction],
	blackboard: WorkerBlackboard
) -> GOAPPlan:
	if goal.is_satisfied(start_state):
		var empty_plan := GOAPPlan.new()
		empty_plan.goal = goal
		return empty_plan

	var open_nodes: Array[PlanNode] = [PlanNode.new(start_state.duplicate_state(), null, null, 0.0)]
	var closed_signatures: Dictionary[String, bool] = {}
	var expansions := 0

	while not open_nodes.is_empty() and expansions < MAX_EXPANSIONS:
		expansions += 1
		open_nodes.sort_custom(_sort_nodes_by_cost)
		var current := open_nodes.pop_front() as PlanNode

		var signature := _state_signature(current.state)
		if closed_signatures.has(signature):
			continue
		closed_signatures[signature] = true

		if goal.is_satisfied(current.state):
			return _reconstruct_plan(current, goal)

		for action: GOAPAction in actions:
			if not action.is_valid_for(blackboard):
				continue
			if not action.are_preconditions_met(current.state):
				continue

			var next_state := action.apply_effects_to(current.state)
			var next_cost := current.cost + action.get_cost(blackboard)
			open_nodes.append(PlanNode.new(next_state, current, action, next_cost))

	return null

static func _sort_nodes_by_cost(a: PlanNode, b: PlanNode) -> bool:
	return a.cost < b.cost

func _reconstruct_plan(node: PlanNode, goal: GOAPGoal) -> GOAPPlan:
	var reversed_actions: Array[GOAPAction] = []
	var total := node.cost
	var cursor := node

	while cursor != null and cursor.action != null:
		reversed_actions.append(cursor.action)
		cursor = cursor.parent

	reversed_actions.reverse()

	var plan := GOAPPlan.new()
	plan.goal = goal
	plan.actions = reversed_actions
	plan.total_cost = total
	return plan

func _state_signature(state: GOAPWorldState) -> String:
	var keys := state.facts.keys()
	keys.sort()

	var parts: Array[String] = []
	for key: StringName in keys:
		parts.append("%s=%s" % [String(key), str(state.facts[key])])

	return "|".join(parts)
