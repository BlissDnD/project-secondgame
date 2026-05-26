extends Node2D
class_name CrystalNodeStation

signal worker_inserted(worker: Worker)
signal worker_removed(worker: Worker)

@export var crystal_node_path: NodePath
@export var max_workers: int = 1
@export var auto_find_radius: float = 128.0

var assigned_workers: Array[Worker] = []

var crystal_node: CrystalNode = null


func _ready() -> void:
	_resolve_crystal_node()


func _resolve_crystal_node() -> void:
	if crystal_node_path != NodePath():
		crystal_node = get_node_or_null(crystal_node_path) as CrystalNode

	if crystal_node != null:
		return

	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("crystal_node"):
		if not node is CrystalNode:
			continue

		var distance := global_position.distance_to(node.global_position)

		if distance > auto_find_radius:
			continue

		if distance < nearest_distance:
			nearest_distance = distance
			crystal_node = node


func can_accept_worker() -> bool:
	if assigned_workers.size() >= max_workers:
		return false

	if crystal_node == null:
		return false

	if not crystal_node.can_be_worked():
		return false

	return true


func insert_worker(worker: Worker) -> bool:
	if worker == null:
		return false

	if not can_accept_worker():
		return false

	if assigned_workers.has(worker):
		return true

	assigned_workers.append(worker)

	worker.on_inserted_into_socket(self)

	worker.assign_work(crystal_node)

	worker_inserted.emit(worker)

	return true


func remove_worker(worker: Worker) -> void:
	if worker == null:
		return

	if not assigned_workers.has(worker):
		return

	assigned_workers.erase(worker)

	worker.on_removed_from_socket(self)

	worker_removed.emit(worker)


func get_crystal_node() -> CrystalNode:
	return crystal_node


func has_valid_work() -> bool:
	if crystal_node == null:
		return false

	return crystal_node.can_be_worked()


func is_worker_assigned(worker: Worker) -> bool:
	return assigned_workers.has(worker)


func get_worker_count() -> int:
	return assigned_workers.size()
