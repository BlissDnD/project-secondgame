extends Node
class_name WorkerBlackboard

@export var worker_path: NodePath = NodePath("..")
@export var stats_path: NodePath = NodePath("../WorkerStatsComponent")
@export var movement_path: NodePath = NodePath("../WorkerMovementComponent")
@export var state_machine_path: NodePath = NodePath("../WorkerStateMachine")
@export var adapter_path: NodePath = NodePath("../WorkerGOAPAdapter")
@export var perception_path: NodePath = NodePath("../WorkerPerceptionComponent")

var world_state: GOAPWorldState = GOAPWorldState.new()

var worker: Worker
var stats: WorkerStatsComponent
var movement: WorkerMovementComponent
var state_machine: WorkerStateMachine
var adapter: WorkerGOAPAdapter
var perception: WorkerPerceptionComponent

var current_target: Node2D = null
var current_target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false

var current_assignment: Node = null
var current_item: Node = null
var carried_item: Node = null

var has_mined_crystal: bool = false
var is_wandering: bool = false

var last_action_id: StringName = &"None"
var last_action_status: StringName = &"None"
var last_failure_reason: String = ""


func _ready() -> void:
	refresh_references()
	update_world_state()


func _process(_delta: float) -> void:
	update_world_state()


func refresh_references() -> void:
	worker = get_node_or_null(worker_path) as Worker
	stats = get_node_or_null(stats_path) as WorkerStatsComponent
	movement = get_node_or_null(movement_path) as WorkerMovementComponent
	state_machine = get_node_or_null(state_machine_path) as WorkerStateMachine
	adapter = get_node_or_null(adapter_path) as WorkerGOAPAdapter
	perception = get_node_or_null(perception_path) as WorkerPerceptionComponent


func update_world_state() -> void:
	world_state.set_fact(&"has_assignment", has_assignment())
	world_state.set_fact(&"has_work_target", has_work_target())

	world_state.set_fact(&"has_target", has_valid_target())
	world_state.set_fact(&"has_target_position", has_target_position)

	world_state.set_fact(&"has_cargo", has_cargo())
	world_state.set_fact(&"has_item", has_cargo())
	world_state.set_fact(&"has_mined_crystal", has_mined_crystal)

	world_state.set_fact(&"stamina_low", has_low_stamina())
	world_state.set_fact(&"can_work", can_work())

	world_state.set_fact(&"at_target", is_at_target())
	world_state.set_fact(&"at_work", is_at_work_target())
	world_state.set_fact(&"at_work_target", is_at_work_target())
	world_state.set_fact(&"at_deposit", is_at_deposit_target())

	world_state.set_fact(&"is_wandering", is_wandering)

	world_state.set_fact(&"has_visible_haulable_item", has_visible_haulable_item())
	world_state.set_fact(&"has_visible_crystal", has_visible_item_type(&"crystal"))

	if worker != null:
		world_state.set_fact(&"worker_has_assignment", worker.has_assignment)
		world_state.set_fact(&"worker_has_crystal_cargo", worker.has_crystal_cargo)

	if state_machine != null:
		world_state.set_fact(&"is_idle", state_machine.current_state == WorkerStateMachine.IDLE)
		world_state.set_fact(&"is_assigned", state_machine.current_state == WorkerStateMachine.ASSIGNED)
		world_state.set_fact(&"is_moving_to_work", state_machine.current_state == WorkerStateMachine.MOVING_TO_WORK)
		world_state.set_fact(&"is_working", state_machine.current_state == WorkerStateMachine.WORKING)
		world_state.set_fact(&"is_carrying", state_machine.current_state == WorkerStateMachine.CARRYING)
		world_state.set_fact(&"is_depositing", state_machine.current_state == WorkerStateMachine.DEPOSITING)
		world_state.set_fact(&"is_recovering", state_machine.current_state == WorkerStateMachine.RECOVERING)
		world_state.set_fact(&"is_failed", state_machine.current_state == WorkerStateMachine.FAILED)


func get_world_state() -> GOAPWorldState:
	update_world_state()
	return world_state


func get_world_state_data() -> Dictionary[StringName, Variant]:
	update_world_state()
	return world_state.facts.duplicate(true)


func set_fact(key: StringName, value: Variant) -> void:
	world_state.set_fact(key, value)

	match key:
		&"has_mined_crystal":
			has_mined_crystal = bool(value)

		&"is_wandering":
			is_wandering = bool(value)

		&"has_cargo", &"has_item":
			if not bool(value):
				carried_item = null


func get_fact(key: StringName, default_value: Variant = null) -> Variant:
	return world_state.get_fact(key, default_value)


# =========================================================
# TARGET
# =========================================================

func set_target(target: Node2D) -> void:
	current_target = target

	if target != null and is_instance_valid(target):
		current_target_position = target.global_position
		has_target_position = true
	else:
		has_target_position = false

	update_world_state()


func set_target_position(position: Vector2) -> void:
	current_target_position = position
	has_target_position = true
	update_world_state()


func set_target_and_position(target: Node2D, position: Vector2) -> void:
	current_target = target
	current_target_position = position
	has_target_position = true
	update_world_state()


func clear_target() -> void:
	current_target = null
	current_target_position = Vector2.ZERO
	has_target_position = false
	update_world_state()


func get_target_position() -> Vector2:
	if has_target_position:
		return current_target_position

	if current_target != null and is_instance_valid(current_target):
		return current_target.global_position

	return Vector2.ZERO


func has_valid_target() -> bool:
	return (current_target != null and is_instance_valid(current_target)) or has_target_position


func is_at_target(distance: float = 18.0) -> bool:
	if worker == null:
		return false

	if not has_valid_target():
		return false

	return worker.global_position.distance_to(get_target_position()) <= distance


# Platformer-safe: X számít, Y kap nagyobb toleranciát.
func is_at_work_target(distance: float = 32.0) -> bool:
	if worker == null:
		return false

	if not has_work_target():
		return false

	var target_position := get_work_target_position()
	var x_distance := absf(worker.global_position.x - target_position.x)
	var y_distance := absf(worker.global_position.y - target_position.y)

	return x_distance <= distance and y_distance <= 96.0


func is_at_deposit_target(distance: float = 64.0) -> bool:
	if worker == null:
		return false

	if current_target == null or not is_instance_valid(current_target):
		return false

	if not current_target.is_in_group("main_crystal"):
		return false

	return worker.global_position.distance_to(get_target_position()) <= distance


# =========================================================
# ASSIGNMENT / WORK TARGET
# =========================================================

func set_assignment(target: Node) -> void:
	current_assignment = target
	update_world_state()


func clear_assignment() -> void:
	current_assignment = null
	update_world_state()


func clear_work_target() -> void:
	clear_assignment()


func has_assignment() -> bool:
	if current_assignment != null and is_instance_valid(current_assignment):
		return true

	return worker != null and worker.has_assignment


func has_work_target() -> bool:
	return get_work_target() != null


func get_work_target() -> Node2D:
	if current_assignment != null and is_instance_valid(current_assignment):
		return current_assignment as Node2D

	if worker != null and "assigned_work_target" in worker:
		var assigned = worker.get("assigned_work_target")

		if assigned != null and is_instance_valid(assigned):
			return assigned as Node2D

	return null


func get_work_target_position() -> Vector2:
	var target := get_work_target()

	if target != null:
		if target.has_method("get_worker_work_position"):
			return target.get_worker_work_position()

		return target.global_position

	return current_target_position


# =========================================================
# STATS
# =========================================================

func has_low_stamina() -> bool:
	return stats != null and stats.has_low_stamina()


func has_recovered_stamina() -> bool:
	return stats != null and stats.has_recovered_stamina()


func can_work() -> bool:
	return stats != null and stats.can_work()


# =========================================================
# PERCEPTION
# =========================================================

func has_visible_haulable_item() -> bool:
	return perception != null and perception.has_visible_item()


func has_visible_item_type(item_type: StringName) -> bool:
	return perception != null and perception.has_visible_item_type(item_type)


func get_nearest_visible_item(item_type: StringName = &"") -> WorldItem:
	if perception == null:
		return null

	return perception.get_nearest_visible_item(item_type)


# =========================================================
# MINING / CARGO
# =========================================================

func set_mined_crystal(value: bool) -> void:
	has_mined_crystal = value
	world_state.set_fact(&"has_mined_crystal", has_mined_crystal)


func clear_mined_crystal() -> void:
	set_mined_crystal(false)


func set_current_item(item: Node) -> void:
	current_item = item


func set_carried_item(item: Node) -> void:
	carried_item = item
	current_item = item

	world_state.set_fact(&"has_cargo", carried_item != null)
	world_state.set_fact(&"has_item", carried_item != null)


func has_cargo() -> bool:
	return carried_item != null and is_instance_valid(carried_item)


func clear_cargo_reference() -> void:
	carried_item = null
	current_item = null

	world_state.set_fact(&"has_cargo", false)
	world_state.set_fact(&"has_item", false)


func clear_cargo_and_free_item() -> void:
	if carried_item != null and is_instance_valid(carried_item):
		carried_item.queue_free()

	clear_cargo_reference()


func clear_cargo() -> void:
	clear_cargo_reference()


func finish_deposit() -> void:
	clear_cargo_reference()
	clear_mined_crystal()
	clear_target()

	world_state.set_fact(&"at_deposit", false)
	world_state.set_fact(&"at_target", false)
	world_state.set_fact(&"has_cargo", false)
	world_state.set_fact(&"has_item", false)
	world_state.set_fact(&"has_mined_crystal", false)

	if stats != null:
		stats.clear_carry_weight()

	if worker != null:
		worker.has_crystal_cargo = false

		if worker.crystal_cargo_visual != null:
			worker.crystal_cargo_visual.visible = false

	update_world_state()


# =========================================================
# ACTION DEBUG
# =========================================================

func set_action_result(action_id: StringName, status_value: StringName, reason: String = "") -> void:
	last_action_id = action_id
	last_action_status = status_value
	last_failure_reason = reason


func get_debug_state() -> Dictionary:
	update_world_state()

	return {
		"target": str(current_target),
		"target_position": current_target_position,
		"has_target_position": has_target_position,
		"assignment": str(current_assignment),
		"current_item": str(current_item),
		"carried_item": str(carried_item),
		"has_mined_crystal": has_mined_crystal,
		"has_visible_haulable_item": has_visible_haulable_item(),
		"has_visible_crystal": has_visible_item_type(&"crystal"),
		"nearest_visible_item": str(get_nearest_visible_item()),
		"is_wandering": is_wandering,
		"last_action_id": str(last_action_id),
		"last_action_status": str(last_action_status),
		"last_failure_reason": last_failure_reason,
		"world_state": world_state.facts.duplicate(true)
	}
