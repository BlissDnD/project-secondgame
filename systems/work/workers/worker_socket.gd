extends Area2D
class_name WorkerSocket

signal worker_inserted(worker: Node)
signal worker_removed(worker: Node)

@export var socket_name: String = "Worker Socket"
@export var snap_worker_to_socket: bool = true
@export var accepted_group: String = "worker"

var inserted_worker: Node


func can_accept_worker(worker: Node) -> bool:
	if inserted_worker != null:
		return false

	if worker == null:
		return false

	if accepted_group != "" and not worker.is_in_group(accepted_group):
		return false

	return true


func insert_worker(worker: Node) -> bool:
	if not can_accept_worker(worker):
		return false

	inserted_worker = worker

	if snap_worker_to_socket and inserted_worker is Node2D:
		inserted_worker.global_position = global_position

	if inserted_worker.has_method("on_inserted_into_socket"):
		inserted_worker.on_inserted_into_socket(self)

	worker_inserted.emit(inserted_worker)
	return true


func remove_worker() -> Node:
	if inserted_worker == null:
		return null

	var worker := inserted_worker
	inserted_worker = null

	if worker.has_method("on_removed_from_socket"):
		worker.on_removed_from_socket(self)

	worker_removed.emit(worker)
	return worker


func has_worker() -> bool:
	return inserted_worker != null
