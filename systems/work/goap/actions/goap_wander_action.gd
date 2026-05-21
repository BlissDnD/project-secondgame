extends GOAPAction
class_name GOAPWanderAction

@export var motor_path: NodePath
@export var actor_path: NodePath

@export var wander_radius_min: float = 48.0
@export var wander_radius_max: float = 160.0
@export var wait_time_min: float = 0.6
@export var wait_time_max: float = 1.8
@export var arrive_distance: float = 12.0

@export var avoid_repick_distance: float = 24.0
@export var max_pick_attempts: int = 8

var motor: WorkerMotor2D
var actor: Node2D

var target_position: Vector2 = Vector2.ZERO
var wait_timer: float = 0.0
var is_waiting: bool = false
var has_destination: bool = false

func _init() -> void:
	action_id = &"wander"
	display_name = "Wander"
	base_cost = 1.0
	interruptible = true
	requires_target = false
	preconditions = {}
	effects = {
		&"is_idle": true
	}

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	motor = blackboard.get_node_or_null(motor_path) as WorkerMotor2D
	actor = blackboard.get_node_or_null(actor_path) as Node2D

	if motor == null:
		push_error("GOAPWanderAction missing motor_path.")
		status = ActionStatus.FAILED
		return

	if actor == null:
		push_error("GOAPWanderAction missing actor_path.")
		status = ActionStatus.FAILED
		return

	blackboard.set_fact(&"is_idle", true)
	_pick_new_destination(blackboard)

func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if motor == null or actor == null:
		return fail()

	# Ha közben lett fontosabb target vagy need, az action interruptible,
	# a GOAPBrain később újratervezhet.
	if blackboard.get_fact(&"needs_rest", false):
		status = ActionStatus.SUCCEEDED
		return status

	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			_pick_new_destination(blackboard)

		status = ActionStatus.RUNNING
		return status

	if not has_destination:
		_pick_new_destination(blackboard)
		status = ActionStatus.RUNNING
		return status

	if actor.global_position.distance_to(target_position) <= arrive_distance:
		motor.stop()
		is_waiting = true
		has_destination = false
		wait_timer = randf_range(wait_time_min, wait_time_max)
		status = ActionStatus.RUNNING
		return status

	status = ActionStatus.RUNNING
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	if motor != null:
		motor.stop()

	is_waiting = false
	has_destination = false
	blackboard.set_fact(&"is_idle", false)

	super.exit(blackboard)

func _pick_new_destination(blackboard: WorkerBlackboard) -> void:
	var origin := actor.global_position
	var picked := origin

	for attempt: int in max_pick_attempts:
		var direction := Vector2.RIGHT
		if randf() < 0.5:
			direction = Vector2.LEFT

		var distance := randf_range(wander_radius_min, wander_radius_max)
		picked = origin + direction * distance

		if picked.distance_to(origin) >= avoid_repick_distance:
			break

	target_position = picked
	blackboard.desired_position = target_position
	blackboard.set_fact(&"wander_target_selected", true)

	has_destination = true
	is_waiting = false
	motor.move_to(target_position)
