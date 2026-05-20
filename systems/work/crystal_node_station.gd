extends PlaceableObject
class_name CrystalNodeStation

@export var crystal_node_search_radius_tiles: int = 2
@export var work_required: float = 5.0
@export var worker_socket: WorkerSocket

var target_node: CrystalNode
var assigned_worker: Node
var work_progress: float = 0.0
var is_working: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("worker_station")
	target_node = find_nearest_crystal_node()

	if worker_socket == null:
		worker_socket = get_node_or_null("WorkerSocket")

	if worker_socket != null:
		worker_socket.worker_inserted.connect(_on_worker_inserted)
		worker_socket.worker_removed.connect(_on_worker_removed)


func find_nearest_crystal_node() -> CrystalNode:
	var best_node: CrystalNode = null
	var best_distance := 999999.0

	for node in get_tree().get_nodes_in_group("crystal_node"):
		if not node is CrystalNode:
			continue

		var distance := global_position.distance_to(node.global_position)
		var max_distance := crystal_node_search_radius_tiles * cell_size.x

		if distance <= max_distance and distance < best_distance:
			best_distance = distance
			best_node = node

	return best_node


func can_accept_worker(worker: Node) -> bool:
	if assigned_worker != null:
		return false

	if target_node == null:
		return false

	if not target_node.can_be_worked():
		return false

	return true


func insert_worker(worker: Node) -> bool:
	if not can_accept_worker(worker):
		return false

	if worker_socket != null:
		return worker_socket.insert_worker(worker)

	_start_work_with_worker(worker)
	return true


func remove_worker() -> void:
	if worker_socket != null and worker_socket.has_worker():
		worker_socket.remove_worker()
		return

	_stop_work()


func _on_worker_inserted(worker: Node) -> void:
	if not can_accept_worker(worker):
		if worker_socket != null:
			worker_socket.remove_worker()
		return

	_start_work_with_worker(worker)


func _on_worker_removed(worker: Node) -> void:
	_stop_work()


func _start_work_with_worker(worker: Node) -> void:
	assigned_worker = worker
	work_progress = 0.0
	is_working = true

	if assigned_worker.has_method("set_worker_state"):
		assigned_worker.set_worker_state(WorkerStateMachine.WORKING_CRYSTAL_NODE)


func _stop_work() -> void:
	if assigned_worker != null:
		if assigned_worker.has_method("set_worker_state"):
			assigned_worker.set_worker_state(WorkerStateMachine.IDLE)

	assigned_worker = null
	is_working = false
	work_progress = 0.0


func _process(delta: float) -> void:
	if not is_working:
		return

	if assigned_worker == null:
		_stop_work()
		return

	if target_node == null:
		_stop_work()
		return

	work_progress += delta

	if assigned_worker.has_method("apply_work_drain"):
		assigned_worker.apply_work_drain(delta)

	if work_progress >= work_required:
		_finish_work_cycle()


func _finish_work_cycle() -> void:
	work_progress = 0.0

	if target_node == null:
		return

	if not target_node.extract_crystal():
		_stop_work()
		return

	var worker := assigned_worker

	if worker_socket != null and worker_socket.has_worker():
		worker_socket.remove_worker()

	assigned_worker = null
	is_working = false

	if worker != null:
		if worker.has_method("receive_crystal_cargo"):
			worker.receive_crystal_cargo()
