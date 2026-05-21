extends Area2D
class_name WorkerSensor2D

signal candidate_seen(candidate: Node)
signal candidate_lost(candidate: Node)

@export var detectable_groups: Array[StringName] = [
	&"worker_interactable",
	&"resource",
	&"infrastructure",
	&"worker"
]

var candidates: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_node_entered)
	area_entered.connect(_on_node_entered)
	body_exited.connect(_on_node_exited)
	area_exited.connect(_on_node_exited)

func get_nearest_candidate(from_position: Vector2, required_group: StringName = &"") -> Node:
	var nearest: Node = null
	var best_distance := INF

	for candidate: Node in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		if required_group != &"" and not candidate.is_in_group(required_group):
			continue
		if not candidate is Node2D:
			continue

		var distance := from_position.distance_squared_to((candidate as Node2D).global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = candidate

	return nearest

func _on_node_entered(node: Node) -> void:
	if node == self:
		return
	if not _is_detectable(node):
		return
	if candidates.has(node):
		return

	candidates.append(node)
	candidate_seen.emit(node)

func _on_node_exited(node: Node) -> void:
	if not candidates.has(node):
		return

	candidates.erase(node)
	candidate_lost.emit(node)

func _is_detectable(node: Node) -> bool:
	for group_name: StringName in detectable_groups:
		if node.is_in_group(group_name):
			return true
	return false
