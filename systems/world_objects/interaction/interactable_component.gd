extends Node
class_name InteractableComponent

@export var enabled: bool = true
@export var interaction_name: String = "Interact"


func can_interact() -> bool:
	return enabled


func interact(actor: Node) -> void:
	print(actor.name, " interacted with ", owner.name)
