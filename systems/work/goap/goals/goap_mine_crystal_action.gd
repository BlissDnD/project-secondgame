extends GOAPAction
class_name GOAPMineCrystalAction

@export var mine_time: float = 1.0

var elapsed: float = 0.0


func _init() -> void:
	action_id = &"mine_crystal"
	display_name = "Mine Crystal"
	base_cost = 0.1
	interruptible = true
	requires_target = true

	preconditions = {
		&"at_work_target": true,
		&"can_work": true,
		&"has_assignment": true,
		&"stamina_low": false
	}

	effects = {
		&"has_mined_crystal": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.has_assignment() \
		and blackboard.has_work_target()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	elapsed = 0.0

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_working()


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if not blackboard.has_assignment():
		return fail("missing_assignment")

	if blackboard.has_cargo():
		return fail("already_has_cargo")

	elapsed += delta

	if elapsed < mine_time:
		status = ActionStatus.RUNNING
		return status

	blackboard.set_mined_crystal(true)

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
