extends GOAPAction
class_name GOAPMoveToTargetAction

@export var motor_path: NodePath
@export var arrive_distance: float = 10.0

var motor: WorkerMotor2D

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	motor = blackboard.get_node_or_null(motor_path) as WorkerMotor2D
	if motor == null:
		status = ActionStatus.FAILED
		return

	var target_position := blackboard.get_target_position()
	motor.move_to(target_position)

func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if motor == null:
		return fail()

	var target_position := blackboard.get_target_position()
	if target_position == Vector2.ZERO and blackboard.current_target == null:
		return fail()

	if motor.actor != null and motor.actor.global_position.distance_to(target_position) <= arrive_distance:
		blackboard.set_fact(&"at_target", true)
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status

func exit(_blackboard: WorkerBlackboard) -> void:
	if motor != null:
		motor.stop()
	super.exit(_blackboard)
