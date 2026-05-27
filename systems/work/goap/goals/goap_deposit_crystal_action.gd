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

	var carried_item: Node = blackboard.carried_item as Node

	if carried_item == null:
		return fail("missing_carried_item")

	var deposit_target := blackboard.current_target

	if deposit_target == null:
		return fail("missing_deposit_target")

	if deposit_target.has_method("deposit_crystal"):
		var amount := 1

		if carried_item.has_method("get_amount"):
			amount = carried_item.get_amount()

		deposit_target.deposit_crystal(amount)

	# ====================================
	# CLEAR ITEM STATE
	# ====================================

	if is_instance_valid(carried_item):
		carried_item.queue_free()

	blackboard.carried_item = null

	blackboard.set_fact(&"has_cargo", false)
	blackboard.set_fact(&"delivered_crystal", true)
	blackboard.set_fact(&"has_item", false)

	blackboard.worker.has_crystal_cargo = false

	if blackboard.worker.crystal_cargo_visual != null:
		blackboard.worker.crystal_cargo_visual.visible = false

	if blackboard.stats != null:
		blackboard.stats.clear_carry_weight()

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.state_machine != null:
		blackboard.state_machine.set_state(
			WorkerStateMachine.IDLE,
			"deposit_complete"
		)

	super.exit(blackboard)
