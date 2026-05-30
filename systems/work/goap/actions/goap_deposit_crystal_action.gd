extends GOAPAction
class_name GOAPDepositCrystalAction


func _init() -> void:
	action_id = &"deposit_crystal"
	display_name = "Deposit Crystal"
	base_cost = 0.5
	interruptible = false
	requires_target = false

	preconditions = {
		&"has_cargo": true,
		&"at_deposit": true
	}

	effects = {
		&"has_cargo": false,
		&"has_item": false,
		&"at_deposit": false
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_depositing()


func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if blackboard.carry_controller == null:
		return fail("missing_worker_carry_controller")

	var item := blackboard.carried_item as WorldItem

	if item == null or not is_instance_valid(item):
		return fail("missing_carried_item")

	var main_crystal := blackboard.worker._find_main_crystal() as MainCrystal

	if main_crystal == null:
		return fail("missing_main_crystal")

	var deposit_position := main_crystal.get_deposit_position()

	if not blackboard.carry_controller.drop_item(deposit_position):
		return fail("deposit_drop_failed")

	main_crystal.deposit_crystal_item(item)

	blackboard.finish_deposit()

	if blackboard.worker != null:
		blackboard.worker.clear_assignment()

	blackboard.clear_assignment()
	blackboard.set_fact(&"has_assignment", false)
	blackboard.set_fact(&"has_work_target", false)

	blackboard.is_wandering = false
	blackboard.set_fact(&"is_wandering", false)

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	if blackboard.movement != null:
		blackboard.movement.reset_movement()

	if blackboard.state_machine != null:
		blackboard.state_machine.set_state(
			WorkerStateMachine.IDLE,
			"deposit_complete"
		)

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
