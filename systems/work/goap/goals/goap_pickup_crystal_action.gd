extends GOAPAction
class_name GOAPPickupCrystalAction

@export var crystal_item_scene: PackedScene


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

	if crystal_item_scene == null:
		return fail("missing_crystal_item_scene")

	var item := crystal_item_scene.instantiate()

	if item == null:
		return fail("failed_to_create_item")

	blackboard.set_carried_item(item)

	blackboard.worker.receive_crystal_cargo()

	blackboard.clear_mined_crystal()

	blackboard.set_fact(&"has_cargo", true)

	status = ActionStatus.SUCCEEDED
	return status
