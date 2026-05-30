extends PhysicalItemBody
class_name CrystalItem

@export var item_type: StringName = &"crystal"
@export var amount: int = 1
@export var is_haulable: bool = true

var reserved_by: Node = null


func get_amount() -> int:
	return amount


func get_item_type() -> StringName:
	return item_type


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
