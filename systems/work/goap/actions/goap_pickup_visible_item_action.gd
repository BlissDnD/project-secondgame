extends GOAPAction
class_name GOAPPickupVisibleItemAction

@export var item_type: StringName = &"crystal"


func _init() -> void:
	action_id = &"pickup_visible_item"
	display_name = "Pickup Visible Item"
	base_cost = 0.5
	interruptible = true
	requires_target = false

	preconditions = {
		&"at_visible_item": true,
		&"has_cargo": false,
		&"has_assignment": false
	}

	effects = {
		&"has_cargo": true,
		&"has_item": true,
		&"at_visible_item": false
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)


func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if blackboard.carry_controller == null:
		return fail("missing_worker_carry_controller")

	var item: WorldItem = blackboard.current_item as WorldItem

	if item == null or not is_instance_valid(item):
		item = blackboard.get_nearest_visible_item(item_type)

	if item == null or not is_instance_valid(item):
		return fail("missing_visible_item")

	if not blackboard.carry_controller.is_item_in_pickup_range(item):
		return fail("item_not_in_pickup_range")

	var success := blackboard.carry_controller.pickup_item(item)

	if not success:
		return fail("pickup_failed")

	blackboard.current_item = item
	blackboard.set_fact(&"has_cargo", true)
	blackboard.set_fact(&"has_item", true)
	blackboard.set_fact(&"at_visible_item", false)

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	super.exit(blackboard)
