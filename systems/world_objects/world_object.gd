extends StaticBody2D
class_name WorldObject

@export var definition: WorldObjectDefinition

var health: int

func _ready() -> void:
	if definition:
		health = definition.max_health

func damage(amount: int) -> void:
	health -= amount

	if health <= 0:
		destroy()

func destroy() -> void:
	# Később itt spawnoljuk a drop itemeket.
	queue_free()
