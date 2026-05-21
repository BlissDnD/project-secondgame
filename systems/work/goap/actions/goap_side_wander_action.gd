extends GOAPAction
class_name GOAPSideWanderAction

@export var side_wander_motor_path: NodePath = NodePath("../WorkerSideWanderMotor")
@export var min_run_time: float = 2.0
@export var max_run_time: float = 5.0

var motor: WorkerSideWanderMotor
var timer: float = 0.0

func _init() -> void:
	action_id = &"side_wander"
	display_name = "Side Wander"
	base_cost = 1.0
	interruptible = true
	requires_target = false
	preconditions = {}
	effects = {
		&"is_idle": true
	}

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	motor = blackboard.get_node_or_null(side_wander_motor_path) as WorkerSideWanderMotor
	if motor == null:
		push_error("GOAPSideWanderAction missing side_wander_motor_path.")
		status = ActionStatus.FAILED
		return

	timer = randf_range(min_run_time, max_run_time)
	blackboard.set_fact(&"is_idle", true)
	motor.start()

func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if motor == null:
		return fail()

	timer -= delta

	if blackboard.get_fact(&"needs_rest", false):
		status = ActionStatus.SUCCEEDED
		return status

	# Fontos: nem SUCCESS azonnal, hanem RUNNING,
	# különben újratervezget folyton.
	if timer <= 0.0:
		timer = randf_range(min_run_time, max_run_time)

	status = ActionStatus.RUNNING
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	if motor != null:
		motor.stop()

	blackboard.set_fact(&"is_idle", false)
	super.exit(blackboard)
