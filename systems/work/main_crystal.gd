extends Node2D
class_name MainCrystal

@export var stored_crystals: int = 0

func _ready() -> void:
	add_to_group("main_crystal")


func deposit_crystal(amount: int = 1) -> void:
	stored_crystals += amount
	print("Main Crystal stored crystals: ", stored_crystals)
