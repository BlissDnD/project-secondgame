extends GOAPAction
class_name GOAPGoToCrystalAction

@export var arrive_distance: float = 24.0


func _init() -> void:
	action_id = &"go_to_crystal"
	display_name = "Go To Crystal"
	base_cost = 1.0
	interruptible = true
	requires_target = true

	preconditions = {
		&"has_assignment": true,
		&"has_work_target": true,
		&"stamina_low": false
	}

	effects = {
		&"at_work_target": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.adapter != null \
		and blackboard.has_assignment() \
		and blackboard.has_work_target() \
		and not blackboard.has_low_stamina()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	if blackboard.adapter != null:
		blackboard.adapter.move_to_work_position(blackboard.get_work_target_position())


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.adapter == null:
		return fail("missing_adapter")

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	blackboard.adapter.move_to_work_position(blackboard.get_work_target_position())

	if blackboard.movement != null and blackboard.movement.has_method("physics_update"):
		blackboard.movement.physics_update(delta)

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_movement(delta)

	if blackboard.is_at_work_target(arrive_distance):
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null and status == ActionStatus.SUCCEEDED:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
