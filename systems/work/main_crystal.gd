extends Node2D
class_name MainCrystal

@export var deposit_point: Node2D
@export var stored_crystal_count: int = 0

var stored_crystal_items: Array[Node] = []


func _ready() -> void:
	add_to_group("main_crystal")


func get_deposit_position() -> Vector2:
	if deposit_point != null:
		return deposit_point.global_position

	return global_position


func deposit_crystal_item(item: Node) -> bool:
	if item == null:
		return false

	stored_crystal_items.append(item)
	stored_crystal_count += _get_item_amount(item)

	print("Main Crystal stored crystals: ", stored_crystal_count)

	return true


func deposit_crystal(amount: int = 1) -> void:
	stored_crystal_count += amount
	print("Main Crystal stored crystals: ", stored_crystal_count)


func _get_item_amount(item: Node) -> int:
	if item.has_method("get_amount"):
		return int(item.get_amount())

	return 1
