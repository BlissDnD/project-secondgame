extends GOAPAction
class_name GOAPGoToCrystalAction

@export var arrive_distance: float = 64.0
@export var debug_enabled: bool = true


func _init() -> void:
	action_id = &"go_to_crystal"
	display_name = "Go To Crystal"
	base_cost = 0.1
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

	if blackboard == null:
		status = ActionStatus.FAILED
		last_failure_reason = "missing_blackboard"
		return

	var work_target := blackboard.get_work_target()

	if work_target == null:
		status = ActionStatus.FAILED
		last_failure_reason = "missing_work_target"
		return

	blackboard.set_target(work_target)

	var target_position := blackboard.get_work_target_position()

	if debug_enabled:
		print(
			"[GO_TO_ENTER]",
			" worker=", blackboard.worker.global_position,
			" target_node=", work_target,
			" target_pos=", target_position,
			" arrive_distance=", arrive_distance
		)

	if blackboard.is_at_work_target(arrive_distance):
		if debug_enabled:
			print("[GO_TO_ENTER] already arrived")

		blackboard.set_fact(&"at_work_target", true)
		blackboard.set_fact(&"at_work", true)
		status = ActionStatus.SUCCEEDED
		return

	if blackboard.adapter != null:
		blackboard.adapter.move_to_work_position(target_position)


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if blackboard.adapter == null:
		return fail("missing_adapter")

	var work_target := blackboard.get_work_target()

	if work_target == null:
		return fail("missing_work_target")

	blackboard.set_target(work_target)

	var target_position := blackboard.get_work_target_position()
	var worker_position := blackboard.worker.global_position
	var distance := worker_position.distance_to(target_position)
	var arrived := blackboard.is_at_work_target(arrive_distance)

	if debug_enabled:
		print(
			"[GO_TO_DEBUG]",
			" worker=", worker_position,
			" target=", target_position,
			" dist=", distance,
			" arrive_distance=", arrive_distance,
			" arrived=", arrived,
			" has_assignment=", blackboard.has_assignment(),
			" has_work_target=", blackboard.has_work_target(),
			" at_work_fact=", blackboard.get_fact(&"at_work_target", false),
			" has_mined=", blackboard.has_mined_crystal,
			" has_cargo=", blackboard.has_cargo()
		)

	if arrived:
		if debug_enabled:
			print("[GO_TO_DEBUG] ARRIVED -> at_work_target=true")

		blackboard.set_fact(&"at_work_target", true)
		blackboard.set_fact(&"at_work", true)

		status = ActionStatus.SUCCEEDED
		return status

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	blackboard.adapter.move_to_work_position(target_position)

	if blackboard.movement != null and blackboard.movement.has_method("physics_update"):
		blackboard.movement.physics_update(delta)

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_movement(delta)

	status = ActionStatus.RUNNING
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if debug_enabled and blackboard != null:
		print(
			"[GO_TO_EXIT]",
			" status=", status,
			" at_work_fact=", blackboard.get_fact(&"at_work_target", false),
			" target=", blackboard.get_work_target_position()
		)

	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
