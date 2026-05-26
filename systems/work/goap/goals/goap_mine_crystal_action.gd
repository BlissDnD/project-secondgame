extends GOAPAction
class_name GOAPMineCrystalAction

@export var mine_duration: float = 2.0

var mine_timer: float = 0.0


func _init() -> void:
	action_id = &"mine_crystal"
	display_name = "Mine Crystal"
	base_cost = 1.2
	interruptible = true
	requires_target = false

	preconditions = {
		&"has_assignment": true,
		&"at_work_target": true,
		&"can_work": true,
		&"stamina_low": false
	}

	effects = {
		&"has_mined_crystal": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.assigned_crystal_node != null \
		and blackboard.is_at_work_target() \
		and blackboard.can_work() \
		and not blackboard.has_low_stamina()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	mine_timer = mine_duration

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_working()


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.assigned_crystal_node == null:
		return fail("missing_crystal_node")

	if not blackboard.assigned_crystal_node.can_be_worked():
		return fail("crystal_cannot_be_worked")

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_work(delta)

	mine_timer -= delta

	if mine_timer > 0.0:
		status = ActionStatus.RUNNING
		return status

	var mined_ok := false

	if blackboard.assigned_crystal_node.has_method("extract_crystal"):
		mined_ok = blackboard.assigned_crystal_node.extract_crystal()

	if not mined_ok:
		return fail("extract_failed")

	blackboard.mark_crystal_mined()

	status = ActionStatus.SUCCEEDED
	return status
