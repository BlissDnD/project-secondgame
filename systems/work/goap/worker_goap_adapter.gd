extends Node
class_name WorkerGOAPAdapter

@export var worker_path: NodePath = NodePath("..")
@export var movement_path: NodePath = NodePath("../WorkerMovementComponent")
@export var state_machine_path: NodePath = NodePath("../WorkerStateMachine")

var worker: Worker
var movement: WorkerMovementComponent
var state_machine: WorkerStateMachine

func _ready() -> void:
	worker = get_node_or_null(worker_path) as Worker
	movement = get_node_or_null(movement_path) as WorkerMovementComponent
	state_machine = get_node_or_null(state_machine_path) as WorkerStateMachine

	if worker == null:
		push_error("WorkerGOAPAdapter missing worker_path.")
	if movement == null:
		push_error("WorkerGOAPAdapter missing movement_path.")
	if state_machine == null:
		push_error("WorkerGOAPAdapter missing state_machine_path.")

func set_idle() -> void:
	if worker != null:
		worker.set_worker_state(WorkerStateMachine.IDLE)

func set_working() -> void:
	if worker != null:
		worker.set_worker_state(WorkerStateMachine.WORKING_CRYSTAL_NODE)

func move_to_position(position: Vector2) -> void:
	if movement == null or worker == null:
		return

	movement.set_target(position)
	worker.set_worker_state(WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN)

func stop_movement() -> void:
	if movement != null:
		movement.clear_target()

func is_at_position(position: Vector2, distance: float = 18.0) -> bool:
	if worker == null:
		return false

	return worker.global_position.distance_to(position) <= distance

func get_position() -> Vector2:
	if worker == null:
		return Vector2.ZERO

	return worker.global_position
