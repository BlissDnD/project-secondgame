extends Node
class_name WorkerBlackboard

@export var worker_path: NodePath = NodePath("..")
@export var stats_path: NodePath = NodePath("../WorkerStatsComponent")
@export var movement_path: NodePath = NodePath("../WorkerMovementComponent")
@export var state_machine_path: NodePath = NodePath("../WorkerStateMachine")
@export var adapter_path: NodePath = NodePath("../WorkerGOAPAdapter")

var world_state: GOAPWorldState = GOAPWorldState.new()

var worker: Worker
var stats: WorkerStatsComponent
var movement: WorkerMovementComponent
var state_machine: WorkerStateMachine
var adapter: WorkerGOAPAdapter
var carried_item: Node = null
var current_target: Node2D = null
var current_target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false

var assigned_station: CrystalNodeStation = null
var assigned_crystal_node: CrystalNode = null

var current_item: Node = null
var current_job: Node = null

var is_wandering: bool = false
var has_mined_crystal: bool = false
var delivered_crystal: bool = false

var last_action_id: StringName = &"None"
var last_action_status: StringName = &"None"
var last_failure_reason: String = ""


func _ready() -> void:
	refresh_references()
	update_world_state()


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


func update_world_state() -> void:
	if world_state == null:
		world_state = GOAPWorldState.new()

	world_state.facts.clear()

	world_state.set_fact(&"has_assignment", has_assignment())
	world_state.set_fact(&"has_target", has_valid_target())
	world_state.set_fact(&"has_work_target", has_work_target())
	world_state.set_fact(&"has_cargo", has_cargo())
	world_state.set_fact(&"has_mined_crystal", has_mined_crystal)
	world_state.set_fact(&"delivered_crystal", delivered_crystal)

	world_state.set_fact(&"stamina_low", has_low_stamina())
	world_state.set_fact(&"can_work", can_work())

	world_state.set_fact(&"at_target", is_at_target())
	world_state.set_fact(&"at_work_target", is_at_work_target())
	world_state.set_fact(&"at_deposit", is_at_target())

	world_state.set_fact(&"is_wandering", is_wandering)

	if worker != null:
		world_state.set_fact(&"is_idle", worker.get_worker_state() == WorkerStateMachine.IDLE)
		world_state.set_fact(&"is_recovering", worker.get_worker_state() == WorkerStateMachine.RECOVERING)
		world_state.set_fact(&"is_working", worker.get_worker_state() == WorkerStateMachine.WORKING)


func get_world_state() -> GOAPWorldState:
	update_world_state()
	return world_state


func set_target(target: Node2D) -> void:
	current_target = target

	if target != null:
		current_target_position = target.global_position
		has_target_position = true
	else:
		current_target_position = Vector2.ZERO
		has_target_position = false

	update_world_state()


func set_target_position(position: Vector2) -> void:
	current_target = null
	current_target_position = position
	has_target_position = true
	update_world_state()


func clear_target() -> void:
	current_target = null
	current_target_position = Vector2.ZERO
	has_target_position = false
	update_world_state()


func set_assigned_station(station: CrystalNodeStation) -> void:
	assigned_station = station
	current_job = station
	delivered_crystal = false
	has_mined_crystal = false

	if assigned_station != null:
		assigned_crystal_node = assigned_station.get_crystal_node()
	else:
		assigned_crystal_node = null

	if assigned_crystal_node != null:
		set_target(assigned_crystal_node)
	else:
		update_world_state()


func clear_assignment_data() -> void:
	assigned_station = null
	assigned_crystal_node = null
	current_job = null
	has_mined_crystal = false
	clear_target()
	update_world_state()


func get_target_position() -> Vector2:
	if current_target != null:
		return current_target.global_position

	return current_target_position


func get_work_target() -> Node2D:
	if assigned_crystal_node != null:
		return assigned_crystal_node

	return current_target


func get_work_target_position() -> Vector2:
	var work_target := get_work_target()

	if work_target != null:
		return work_target.global_position

	return get_target_position()


func has_valid_target() -> bool:
	return current_target != null or has_target_position


func has_work_target() -> bool:
	return assigned_crystal_node != null


func is_at_target(distance: float = 18.0) -> bool:
	if worker == null:
		return false

	if not has_valid_target():
		return false

	return worker.global_position.distance_to(get_target_position()) <= distance


func is_at_work_target(distance: float = 24.0) -> bool:
	if worker == null:
		return false

	if not has_work_target():
		return false

	return worker.global_position.distance_to(get_work_target_position()) <= distance


func has_low_stamina() -> bool:
	return stats != null and stats.is_stamina_low


func has_recovered_stamina() -> bool:
	return stats != null and stats.has_recovered_stamina()


func can_work() -> bool:
	return stats != null and stats.can_work()


func has_assignment() -> bool:
	return worker != null and worker.has_assignment


func has_cargo() -> bool:
	return worker != null and worker.has_crystal_cargo


func mark_crystal_mined() -> void:
	has_mined_crystal = true
	update_world_state()


func clear_mined_crystal() -> void:
	has_mined_crystal = false
	update_world_state()


func mark_delivered_crystal() -> void:
	delivered_crystal = true
	update_world_state()


func clear_delivered_crystal() -> void:
	delivered_crystal = false
	update_world_state()


func set_action_result(action_id: StringName, status: StringName, reason: String = "") -> void:
	last_action_id = action_id
	last_action_status = status
	last_failure_reason = reason


func get_world_state_data() -> Dictionary[StringName, Variant]:
	update_world_state()

	return {
		&"has_assignment": has_assignment(),
		&"has_target": has_valid_target(),
		&"has_work_target": has_work_target(),
		&"has_cargo": has_cargo(),
		&"has_mined_crystal": has_mined_crystal,
		&"delivered_crystal": delivered_crystal,
		&"stamina_low": has_low_stamina(),
		&"can_work": can_work(),
		&"at_target": is_at_target(),
		&"at_work_target": is_at_work_target(),
		&"at_deposit": is_at_target(),
		&"is_wandering": is_wandering
	}


func get_debug_state() -> Dictionary:
	return {
		"target": str(current_target),
		"target_position": current_target_position,
		"assigned_station": str(assigned_station),
		"assigned_crystal_node": str(assigned_crystal_node),
		"has_target_position": has_target_position,
		"current_item": str(current_item),
		"current_job": str(current_job),
		"is_wandering": is_wandering,
		"has_mined_crystal": has_mined_crystal,
		"delivered_crystal": delivered_crystal,
		"last_action_id": str(last_action_id),
		"last_action_status": str(last_action_status),
		"last_failure_reason": last_failure_reason
	}
