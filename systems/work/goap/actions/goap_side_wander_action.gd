extends GOAPAction
class_name GOAPSideWanderAction

@export var min_run_time: float = 2.0
@export var max_run_time: float = 5.0

var movement: WorkerMovementComponent
var timer: float = 0.0


func _init() -> void:
	action_id = &"side_wander"
	display_name = "Side Wander"
	base_cost = 1.0
	interruptible = true
	requires_target = false

	preconditions = {
		&"has_assignment": false,
		&"stamina_low": false
	}

	effects = {
		&"is_wandering": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.movement != null \
		and not blackboard.has_assignment() \
		and not blackboard.has_low_stamina()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	movement = blackboard.movement
	timer = randf_range(min_run_time, max_run_time)

	blackboard.is_wandering = true
	blackboard.update_world_state()

	if blackboard.adapter != null:
		blackboard.adapter.set_idle()

	if movement != null and movement.has_method("start_wander"):
		movement.start_wander()
	else:
		status = ActionStatus.FAILED
		last_failure_reason = "movement_missing_start_wander"


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if movement == null:
		return fail("missing_movement")

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	if blackboard.has_assignment():
		return interrupt(blackboard, "assignment_received")

	if movement.has_method("physics_update"):
		movement.physics_update(delta)

	if blackboard.stats != null:
		blackboard.stats.drain_stamina_for_movement(delta)

	timer -= delta

	if timer <= 0.0:
		timer = randf_range(min_run_time, max_run_time)

	status = ActionStatus.RUNNING
	return status



func exit(blackboard: WorkerBlackboard) -> void:
	if movement != null and movement.has_method("stop_wander"):
		movement.stop_wander()

	if blackboard != null:
		blackboard.is_wandering = false
		blackboard.update_world_state()

	super.exit(blackboard)
