extends GOAPAction
class_name GOAPRestAction


func _init() -> void:
	action_id = &"rest"
	display_name = "Rest"
	base_cost = 1.0
	interruptible = false
	requires_target = false
	preconditions = {}
	effects = {
		&"stamina_low": false,
		&"can_work": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null and blackboard.stats != null


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_recovering()


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.stats == null:
		return fail("missing_stats")

	blackboard.stats.recover_stamina(delta)

	if blackboard.stats.has_recovered_stamina():
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.worker != null and blackboard.state_machine != null:
		blackboard.state_machine.return_from_recovery(blackboard.worker.has_assignment)

	super.exit(blackboard)
