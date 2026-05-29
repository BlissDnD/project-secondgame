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
		&"has_cargo": false
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

	if not blackboard.has_cargo():
		return fail("missing_cargo")

	var item := blackboard.carried_item as Node2D

	if item == null or not is_instance_valid(item):
		return fail("missing_carried_item")

	var main_crystal := blackboard.worker._find_main_crystal() as MainCrystal

	if main_crystal == null:
		return fail("missing_main_crystal")

	var world := blackboard.worker.get_tree().current_scene

	if world == null:
		return fail("missing_world")

	item.reparent(world, false)
	item.global_position = main_crystal.get_deposit_position()
	item.rotation = 0.0

	main_crystal.deposit_crystal_item(item)

	blackboard.carried_item = null
	blackboard.current_item = null
	blackboard.set_fact(&"has_cargo", false)
	blackboard.set_fact(&"has_item", false)
	blackboard.clear_mined_crystal()

	blackboard.worker.has_crystal_cargo = false

	if blackboard.worker.crystal_cargo_visual != null:
		blackboard.worker.crystal_cargo_visual.visible = false

	if blackboard.stats != null:
		blackboard.stats.clear_carry_weight()

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
