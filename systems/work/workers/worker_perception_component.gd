extends Node
class_name WorkerPerceptionComponent

@export var worker_path: NodePath = NodePath("..")
@export var vision_area: Area2D
@export var refresh_interval: float = 0.15

var worker: Node2D = null
var visible_items: Array[WorldItem] = []

var _refresh_timer: float = 0.0


func _ready() -> void:
	worker = get_node_or_null(worker_path) as Node2D

	if vision_area == null:
		vision_area = find_child("VisionArea", true, false) as Area2D

	if vision_area == null:
		push_warning("WorkerPerceptionComponent: missing VisionArea.")


func _process(delta: float) -> void:
	_refresh_timer -= delta

	if _refresh_timer > 0.0:
		return

	_refresh_timer = refresh_interval
	refresh_perception()


func refresh_perception() -> void:
	visible_items.clear()

	if vision_area == null:
		return

	for body in vision_area.get_overlapping_bodies():
		var item := _find_world_item_from_node(body)

		if item == null:
			continue

		if not item.is_haulable:
			continue

		if not item.can_be_hauled_by(worker):
			continue

		if visible_items.has(item):
			continue

		visible_items.append(item)

	for area in vision_area.get_overlapping_areas():
		var item := _find_world_item_from_node(area)

		if item == null:
			continue

		if not item.is_haulable:
			continue

		if not item.can_be_hauled_by(worker):
			continue

		if visible_items.has(item):
			continue

		visible_items.append(item)


func get_visible_items() -> Array[WorldItem]:
	return visible_items.duplicate()


func has_visible_item() -> bool:
	return visible_items.size() > 0


func get_nearest_visible_item(item_type: StringName = &"") -> WorldItem:
	if worker == null:
		return null

	var best_item: WorldItem = null
	var best_distance := INF

	for item in visible_items:
		if item == null or not is_instance_valid(item):
			continue

		if item_type != &"" and item.get_item_type() != item_type:
			continue

		var distance := worker.global_position.distance_to(item.global_position)

		if distance < best_distance:
			best_distance = distance
			best_item = item

	return best_item


func has_visible_item_type(item_type: StringName) -> bool:
	return get_nearest_visible_item(item_type) != null


func _find_world_item_from_node(node: Node) -> WorldItem:
	var current := node

	while current != null:
		if current is WorldItem:
			return current as WorldItem

		current = current.get_parent()

	return null
