extends GOAPAction
class_name GOAPGoToVisibleItemAction

@export var item_type: StringName = &"crystal"


func _init() -> void:
	action_id = &"go_to_visible_item"
	display_name = "Go To Visible Item"
	base_cost = 0.5
	interruptible = true
	requires_target = false

	preconditions = {
		&"has_visible_crystal": true,
		&"has_cargo": false,
		&"has_assignment": false
	}

	effects = {
		&"at_visible_item": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.adapter != null \
		and not blackboard.has_assignment() \
		and not blackboard.has_cargo() \
		and blackboard.has_visible_item_type(item_type)


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	var item := blackboard.get_nearest_visible_item(item_type)

	if item == null or not is_instance_valid(item):
		status = ActionStatus.FAILED
		last_failure_reason = "missing_visible_item"
		return

	blackboard.current_item = item
	blackboard.set_target_position(item.get_world_position())
	blackboard.set_fact(&"has_item_target", true)
	blackboard.set_fact(&"at_visible_item", false)

	if blackboard.adapter != null:
		blackboard.adapter.move_to_position(item.get_world_position())


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if blackboard.adapter == null:
		return fail("missing_adapter")

	var item := blackboard.current_item as WorldItem

	if item == null or not is_instance_valid(item):
		item = blackboard.get_nearest_visible_item(item_type)

	if item == null or not is_instance_valid(item):
		_clear_item_target(blackboard)

		if blackboard.state_machine != null:
			blackboard.state_machine.set_state(
				WorkerStateMachine.IDLE,
				"lost_visible_item"
			)

		status = ActionStatus.SUCCEEDED
		return status

	blackboard.current_item = item

	var target_position := item.get_world_position()

	blackboard.set_target_position(target_position)
	blackboard.adapter.move_to_position(target_position)

	if blackboard.movement != null and blackboard.movement.has_method("physics_update"):
		blackboard.movement.physics_update(delta)

	if blackboard.carry_controller != null \
	and blackboard.carry_controller.is_item_in_pickup_range(item):
		blackboard.set_fact(&"at_visible_item", true)
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)


func _clear_item_target(blackboard: WorkerBlackboard) -> void:
	if blackboard == null:
		return

	blackboard.current_item = null
	blackboard.clear_target()
	blackboard.set_fact(&"has_item_target", false)
	blackboard.set_fact(&"at_visible_item", false)
	blackboard.is_wandering = false
	blackboard.set_fact(&"is_wandering", false)
