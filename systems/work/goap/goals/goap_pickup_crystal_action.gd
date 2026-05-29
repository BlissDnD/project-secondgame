extends GOAPAction
class_name GOAPPickupCrystalAction


func _init() -> void:
	action_id = &"pickup_crystal"
	display_name = "Pickup Crystal"
	base_cost = 0.5
	interruptible = true
	requires_target = false

	preconditions = {
		&"has_assignment": true,
		&"has_mined_crystal": true
	}

	effects = {
		&"has_cargo": true
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

	if blackboard.current_item == null or not is_instance_valid(blackboard.current_item):
		return fail("missing_mined_item")

	var item := blackboard.current_item as Node2D

	if item == null:
		return fail("mined_item_not_node2d")

	var hold_point := blackboard.worker.get_cargo_hold_point()

	if hold_point == null:
		return fail("missing_cargo_hold_point")

	item.reparent(hold_point, false)
	item.position = Vector2.ZERO
	item.rotation = 0.0

	blackboard.set_carried_item(item)
	blackboard.clear_mined_crystal()

	blackboard.worker.receive_crystal_cargo()

	if blackboard.stats != null:
		blackboard.stats.add_carry_weight(1.0)

	status = ActionStatus.SUCCEEDED
	return status
