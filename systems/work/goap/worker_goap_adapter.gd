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
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.IDLE, "goap_set_idle")


func set_assigned() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.ASSIGNED, "goap_set_assigned")


func set_moving_to_work() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.MOVING_TO_WORK, "goap_set_moving_to_work")


func set_working() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.WORKING, "goap_set_working")


func set_carrying() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.CARRYING, "goap_set_carrying")


func set_depositing() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.DEPOSITING, "goap_set_depositing")


func set_recovering() -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.RECOVERING, "goap_set_recovering")


func set_failed(reason: String = "goap_failed") -> void:
	if worker == null:
		return

	worker.set_worker_state(WorkerStateMachine.FAILED, reason)


func move_to_position(target_position: Vector2, state: StringName = WorkerStateMachine.MOVING_TO_WORK) -> void:
	if movement == null or worker == null:
		return

	movement.set_target(target_position)
	worker.set_worker_state(state, "goap_move_to_position")


func move_to_work_position(target_position: Vector2) -> void:
	move_to_position(target_position, WorkerStateMachine.MOVING_TO_WORK)


func move_to_deposit_position(target_position: Vector2) -> void:
	move_to_position(target_position, WorkerStateMachine.CARRYING)


func stop_movement() -> void:
	if movement == null:
		return

	movement.clear_target()


func is_at_position(target_position: Vector2, distance: float = 18.0) -> bool:
	if worker == null:
		return false

	return worker.global_position.distance_to(target_position) <= distance


func get_position() -> Vector2:
	if worker == null:
		return Vector2.ZERO

	return worker.global_position


func has_worker() -> bool:
	return worker != null


func has_movement() -> bool:
	return movement != null


func has_state_machine() -> bool:
	return state_machine != null
