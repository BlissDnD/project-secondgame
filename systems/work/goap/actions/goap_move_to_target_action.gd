extends GOAPAction
class_name GOAPMoveToTargetAction

@export var arrive_distance: float = 18.0
@export var max_stuck_time: float = 2.0
@export var min_position_change: float = 2.0

var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO


func _init() -> void:
	action_id = &"move_to_target"
	display_name = "Move To Target"
	base_cost = 1.0
	interruptible = true
	requires_target = true
	preconditions = {
		&"has_target": true,
		&"stamina_low": false
	}
	effects = {
		&"at_target": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.movement != null \
		and blackboard.adapter != null \
		and blackboard.has_valid_target()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	stuck_timer = 0.0

	if blackboard.worker != null:
		last_position = blackboard.worker.global_position

	if blackboard.adapter != null:
		blackboard.adapter.move_to_work_position(blackboard.get_target_position())


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if not blackboard.has_valid_target():
		return fail("missing_target")

	if blackboard.worker == null:
		return fail("missing_worker")

	if blackboard.adapter == null:
		return fail("missing_adapter")

	if blackboard.stats != null and blackboard.stats.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	blackboard.adapter.move_to_work_position(blackboard.get_target_position())

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_movement(delta)

	if blackboard.is_at_target(arrive_distance):
		status = ActionStatus.SUCCEEDED
		return status

	_update_stuck_detection(blackboard, delta)

	if stuck_timer >= max_stuck_time:
		return fail("stuck")

	status = ActionStatus.RUNNING
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)

func _update_stuck_detection(blackboard: WorkerBlackboard, delta: float) -> void:
	var current_position := blackboard.worker.global_position
	var moved_distance := current_position.distance_to(last_position)

	if moved_distance < min_position_change:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		last_position = current_position
