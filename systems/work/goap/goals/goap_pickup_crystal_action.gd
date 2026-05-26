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
		and blackboard.worker != null \
		and blackboard.has_mined_crystal \
		and not blackboard.has_cargo()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)


func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if not blackboard.has_mined_crystal:
		return fail("nothing_mined")

	blackboard.worker.receive_crystal_cargo()
	blackboard.clear_mined_crystal()

	status = ActionStatus.SUCCEEDED
	return status
