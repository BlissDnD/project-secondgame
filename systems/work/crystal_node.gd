extends Node2D
class_name CrystalNode

@export var available_crystals: int = 999
@export var work_required: float = 5.0

func _ready() -> void:
	add_to_group("crystal_node")


func can_be_worked() -> bool:
	return available_crystals > 0


func extract_crystal() -> bool:
	if available_crystals <= 0:
		return false

	available_crystals -= 1
	return true
