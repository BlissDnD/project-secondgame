extends GOAPAction
class_name GOAPCarryToMainCrystalAction

@export var arrive_distance: float = 28.0


func _init() -> void:
	action_id = &"carry_to_main_crystal"
	display_name = "Carry To Main Crystal"
	base_cost = 1.0
	interruptible = true
	requires_target = false

	preconditions = {
		&"has_cargo": true,
		&"stamina_low": false
	}

	effects = {
		&"at_deposit": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.adapter != null \
		and blackboard.has_cargo() \
		and not blackboard.has_low_stamina()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	var main_crystal := blackboard.worker._find_main_crystal()

	if main_crystal == null:
		status = ActionStatus.FAILED
		last_failure_reason = "missing_main_crystal"
		return

	blackboard.set_target(main_crystal)

	if blackboard.adapter != null:
		blackboard.adapter.move_to_deposit_position(main_crystal.global_position)


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if not blackboard.has_cargo():
		return fail("missing_cargo")

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	if not blackboard.has_valid_target():
		return fail("missing_deposit_target")

	blackboard.adapter.move_to_deposit_position(blackboard.get_target_position())

	if blackboard.movement != null and blackboard.movement.has_method("physics_update"):
		blackboard.movement.physics_update(delta)

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_movement(delta)

	if blackboard.is_at_target(arrive_distance):
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null and status == ActionStatus.SUCCEEDED:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
