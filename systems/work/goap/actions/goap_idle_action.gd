extends GOAPAction
class_name GOAPIdleAction

@export var idle_duration_min: float = 0.6
@export var idle_duration_max: float = 1.8

var idle_timer: float = 0.0


func _init() -> void:
	action_id = &"idle"
	display_name = "Idle"
	base_cost = 0.5
	interruptible = true
	requires_target = false
	preconditions = {
		&"has_assignment": false,
		&"stamina_low": false
	}
	effects = {
		&"is_idle": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null and blackboard.worker != null


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	idle_timer = randf_range(idle_duration_min, idle_duration_max)

	if blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_idle()


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.has_low_stamina():
		return interrupt(blackboard, "stamina_low")

	if blackboard.has_assignment():
		return interrupt(blackboard, "assignment_received")

	idle_timer -= delta

	if idle_timer <= 0.0:
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status
