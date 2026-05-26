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
		&"delivered_crystal": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.has_cargo() \
		and blackboard.has_valid_target()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_depositing()


func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if not blackboard.has_cargo():
		return fail("missing_cargo")

	var deposit_target := blackboard.current_target

	if deposit_target == null:
		return fail("missing_deposit_target")

	if deposit_target.has_method("deposit_crystal"):
		deposit_target.deposit_crystal(1)

	blackboard.worker.has_crystal_cargo = false
	blackboard.worker.has_assignment = false
	blackboard.worker.main_crystal_target = null

	if blackboard.worker.crystal_cargo_visual != null:
		blackboard.worker.crystal_cargo_visual.visible = false

	if blackboard.stats != null:
		blackboard.stats.clear_carry_weight()

	blackboard.clear_assignment_data()

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.state_machine != null:
		blackboard.state_machine.set_state(WorkerStateMachine.IDLE, "deposit_complete")

	super.exit(blackboard)
