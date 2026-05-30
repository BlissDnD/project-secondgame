extends Node2D
class_name WorldItem
var stored_in_main_crystal: bool = false
@export var item_type: StringName = &"item"
@export var display_name: String = "Item"
@export var amount: int = 1
@export var is_haulable: bool = true

var reserved_by: Node = null


func get_item_type() -> StringName:
	return item_type


func get_amount() -> int:
	return amount


func get_weight() -> float:
	var body := get_physical_body()

	if body != null and body.has_method("get_motion_profile"):
		var profile = body.get_motion_profile()

		if profile != null:
			return profile.weight

	return 1.0


func can_be_hauled_by(worker: Node) -> bool:
	if not is_haulable:
		return false

	if reserved_by != null and reserved_by != worker:
		return false

	return true


func reserve(worker: Node) -> bool:
	if not can_be_hauled_by(worker):
		return false

	reserved_by = worker
	return true


func clear_reservation(worker: Node = null) -> void:
	if worker == null:
		reserved_by = null
		return

	if reserved_by == worker:
		reserved_by = null


func is_reserved() -> bool:
	return reserved_by != null


func get_physical_body() -> PhysicalItemBody:
	for child in get_children():
		if child is PhysicalItemBody:
			return child as PhysicalItemBody

	return null


func get_carryable_component() -> CarryableComponent:
	var body := get_physical_body()

	if body == null:
		return null

	for child in body.get_children():
		if child is CarryableComponent:
			return child as CarryableComponent

	return null
