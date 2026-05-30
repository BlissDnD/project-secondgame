extends Node2D
class_name MainCrystal

@export var deposit_point: Node2D
@export var stored_crystal_count: int = 0
@export var hide_stored_items: bool = true
@export var storage_area: Area2D
var stored_crystal_items: Array[Node] = []


func _ready() -> void:
	add_to_group("main_crystal")


func get_deposit_position() -> Vector2:
	if deposit_point != null:
		return deposit_point.global_position

	return global_position
	
func contains_world_position(world_position: Vector2) -> bool:
	if storage_area == null:
		return false

	for child in storage_area.get_children():
		var shape_node := child as CollisionShape2D

		if shape_node == null:
			continue

		if shape_node.disabled:
			continue

		var shape := shape_node.shape

		if shape == null:
			continue

		var local_position := shape_node.to_local(world_position)

		if shape is RectangleShape2D:
			var rect_shape := shape as RectangleShape2D
			var half_size := rect_shape.size * 0.5

			return absf(local_position.x) <= half_size.x \
				and absf(local_position.y) <= half_size.y

		if shape is CircleShape2D:
			var circle_shape := shape as CircleShape2D
			return local_position.length() <= circle_shape.radius

	return false
func deposit_crystal_item(item: Node) -> bool:
	if item == null:
		return false

	if not is_instance_valid(item):
		return false

	if item.has_method("clear_reservation"):
		item.clear_reservation()

	if "stored_in_main_crystal" in item:
		item.stored_in_main_crystal = true

	if hide_stored_items and item is CanvasItem:
		(item as CanvasItem).visible = false

	stored_crystal_items.append(item)
	stored_crystal_count += _get_item_amount(item)

	print("Main Crystal stored crystals: ", stored_crystal_count)

	return true


func release_crystal_item(item: Node, release_position: Vector2) -> bool:
	if item == null:
		return false

	if not stored_crystal_items.has(item):
		return false

	stored_crystal_items.erase(item)

	if "stored_in_main_crystal" in item:
		item.stored_in_main_crystal = false

	if item is CanvasItem:
		(item as CanvasItem).visible = true

	if item is Node2D:
		(item as Node2D).global_position = release_position

	return true


func deposit_crystal(amount: int = 1) -> void:
	stored_crystal_count += amount
	print("Main Crystal stored crystals: ", stored_crystal_count)


func _get_item_amount(item: Node) -> int:
	if item != null and item.has_method("get_amount"):
		return int(item.get_amount())

	return 1
