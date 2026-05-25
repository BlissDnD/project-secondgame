extends Node
class_name WorkerBlackboard

@export var worker_path: NodePath = NodePath("..")
@export var stats_path: NodePath = NodePath("../WorkerStatsComponent")
@export var movement_path: NodePath = NodePath("../WorkerMovementComponent")
@export var state_machine_path: NodePath = NodePath("../WorkerStateMachine")
@export var adapter_path: NodePath = NodePath("../WorkerGOAPAdapter")

var worker: Worker
var stats: WorkerStatsComponent
var movement: WorkerMovementComponent
var state_machine: WorkerStateMachine
var adapter: WorkerGOAPAdapter

var current_target: Node2D = null
var current_target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false

var current_item: Node = null
var current_job: Node = null

var last_action_id: StringName = &"None"
var last_action_status: StringName = &"None"
var last_failure_reason: String = ""


func _ready() -> void:
	refresh_references()


func refresh_references() -> void:
	worker = get_node_or_null(worker_path) as Worker
	stats = get_node_or_null(stats_path) as WorkerStatsComponent
	movement = get_node_or_null(movement_path) as WorkerMovementComponent
	state_machine = get_node_or_null(state_machine_path) as WorkerStateMachine
	adapter = get_node_or_null(adapter_path) as WorkerGOAPAdapter

	if worker == null:
		push_error("WorkerBlackboard missing worker reference.")

	if stats == null:
		push_error("WorkerBlackboard missing stats reference.")

	if movement == null:
		push_error("WorkerBlackboard missing movement reference.")

	if state_machine == null:
		push_error("WorkerBlackboard missing state_machine reference.")

	if adapter == null:
		push_error("WorkerBlackboard missing adapter reference.")


func set_target(target: Node2D) -> void:
	current_target = target

	if target != null:
		current_target_position = target.global_position
		has_target_position = true
	else:
		has_target_position = false


func set_target_position(position: Vector2) -> void:
	current_target = null
	current_target_position = position
	has_target_position = true


func clear_target() -> void:
	current_target = null
	current_target_position = Vector2.ZERO
	has_target_position = false


func get_target_position() -> Vector2:
	if current_target != null:
		return current_target.global_position

	return current_target_position


func has_valid_target() -> bool:
	return current_target != null or has_target_position


func is_at_target(distance: float = 18.0) -> bool:
	if worker == null:
		return false

	if not has_valid_target():
		return false

	return worker.global_position.distance_to(get_target_position()) <= distance


func has_low_stamina() -> bool:
	return stats != null and stats.has_low_stamina()


func has_recovered_stamina() -> bool:
	return stats != null and stats.has_recovered_stamina()


func can_work() -> bool:
	return stats != null and stats.can_work()


func has_assignment() -> bool:
	return worker != null and worker.has_assignment


func has_cargo() -> bool:
	return worker != null and worker.has_crystal_cargo


func set_action_result(action_id: StringName, status: StringName, reason: String = "") -> void:
	last_action_id = action_id
	last_action_status = status
	last_failure_reason = reason


func get_world_state_data() -> Dictionary[StringName, Variant]:
	return {
		&"has_assignment": has_assignment(),
		&"has_target": has_valid_target(),
		&"has_cargo": has_cargo(),
		&"stamina_low": has_low_stamina(),
		&"can_work": can_work()
	}


func get_debug_state() -> Dictionary:
	return {
		"target": str(current_target),
		"target_position": current_target_position,
		"has_target_position": has_target_position,
		"current_item": str(current_item),
		"current_job": str(current_job),
		"last_action_id": str(last_action_id),
		"last_action_status": str(last_action_status),
		"last_failure_reason": last_failure_reason
	}
