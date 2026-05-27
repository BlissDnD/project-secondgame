extends Node2D
class_name CrystalItem

@export var amount: int = 1
@export var item_type: StringName = &"crystal"


func get_amount() -> int:
	return amount


func get_item_type() -> StringName:
	return item_type
