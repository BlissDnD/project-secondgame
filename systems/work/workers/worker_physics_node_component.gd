extends Node
class_name WorkerPhysicsModeComponent

signal mode_changed(old_mode: StringName, new_mode: StringName)
signal physicalized_started(proxy: WorkerPhysicsProxy)
signal physicalized_finished(proxy: WorkerPhysicsProxy)

enum Mode {
	AI_CONTROLLED,
	CARRIED,
	PHYSICALIZED
}

@export var worker_path: NodePath = NodePath("..")
@export var physics_proxy_scene: PackedScene
@export var proxy_parent_path: NodePath
@export var nodes_to_disable_while_not_ai: Array[NodePath] = []

var worker: Worker
var mode: Mode = Mode.AI_CONTROLLED
var current_proxy: WorkerPhysicsProxy = null


func _ready() -> void:
	worker = get_node_or_null(worker_path) as Worker

	if worker == null:
		push_error("WorkerPhysicsModeComponent missing worker.")

	if proxy_parent_path == NodePath():
		proxy_parent_path = NodePath("/root")


func begin_carried() -> void:
	_set_mode(Mode.CARRIED)
	_disable_ai_nodes()
	_stop_worker_motion()


func end_carried() -> void:
	if mode != Mode.CARRIED:
		return

	_enable_ai_nodes()
	_set_mode(Mode.AI_CONTROLLED)


func start_external_motion(initial_velocity: Vector2) -> void:
	begin_physicalized(initial_velocity)


func begin_physicalized(initial_velocity: Vector2 = Vector2.ZERO) -> void:
	if worker == null:
		return

	if physics_proxy_scene == null:
		push_error("WorkerPhysicsModeComponent missing physics_proxy_scene.")
		return

	_stop_worker_motion()
	_disable_ai_nodes()
	_hide_worker_for_proxy()

	var parent := _get_proxy_parent()
	current_proxy = physics_proxy_scene.instantiate() as WorkerPhysicsProxy

	if current_proxy == null:
		push_error("physics_proxy_scene root must be WorkerPhysicsProxy.")
		_show_worker_after_proxy()
		_enable_ai_nodes()
		return

	parent.add_child(current_proxy)
	current_proxy.setup_from_worker(worker, initial_velocity)
	current_proxy.proxy_sleep_ready.connect(_on_proxy_sleep_ready)

	_set_mode(Mode.PHYSICALIZED)
	physicalized_started.emit(current_proxy)


func end_physicalized() -> void:
	if current_proxy == null:
		_show_worker_after_proxy()
		_enable_ai_nodes()
		_set_mode(Mode.AI_CONTROLLED)
		return

	worker.global_position = current_proxy.global_position
	worker.rotation = 0.0

	var old_proxy := current_proxy
	current_proxy = null

	if is_instance_valid(old_proxy):
		old_proxy.queue_free()

	_show_worker_after_proxy()
	_enable_ai_nodes()
	_stop_worker_motion()

	_set_mode(Mode.AI_CONTROLLED)
	physicalized_finished.emit(old_proxy)


func apply_external_impulse(impulse_velocity: Vector2) -> void:
	if mode == Mode.PHYSICALIZED and current_proxy != null:
		current_proxy.linear_velocity += impulse_velocity
		return

	begin_physicalized(impulse_velocity)


func is_ai_controlled() -> bool:
	return mode == Mode.AI_CONTROLLED


func is_carried() -> bool:
	return mode == Mode.CARRIED


func is_physicalized() -> bool:
	return mode == Mode.PHYSICALIZED


func _on_proxy_sleep_ready(proxy: WorkerPhysicsProxy) -> void:
	if proxy != current_proxy:
		return

	end_physicalized()


func _set_mode(new_mode: Mode) -> void:
	if mode == new_mode:
		return

	var old := _mode_to_name(mode)
	mode = new_mode
	mode_changed.emit(old, _mode_to_name(mode))


func _mode_to_name(value: Mode) -> StringName:
	match value:
		Mode.AI_CONTROLLED:
			return &"ai_controlled"
		Mode.CARRIED:
			return &"carried"
		Mode.PHYSICALIZED:
			return &"physicalized"

	return &"unknown"


func _disable_ai_nodes() -> void:
	for path in nodes_to_disable_while_not_ai:
		var node := get_node_or_null(path)

		if node == null:
			continue

		node.set_process(false)
		node.set_physics_process(false)


func _enable_ai_nodes() -> void:
	for path in nodes_to_disable_while_not_ai:
		var node := get_node_or_null(path)

		if node == null:
			continue

		node.set_process(true)
		node.set_physics_process(true)


func _stop_worker_motion() -> void:
	if worker == null:
		return

	if worker is CharacterBody2D:
		(worker as CharacterBody2D).velocity = Vector2.ZERO


func _hide_worker_for_proxy() -> void:
	if worker == null:
		return

	worker.visible = false
	worker.set_physics_process(false)


func _show_worker_after_proxy() -> void:
	if worker == null:
		return

	worker.visible = true
	worker.set_physics_process(true)


func _get_proxy_parent() -> Node:
	var parent := get_node_or_null(proxy_parent_path)

	if parent != null:
		return parent

	if worker != null and worker.get_parent() != null:
		return worker.get_parent()

	return get_tree().current_scene
