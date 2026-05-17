extends Node
class_name CarryableComponent

@export var enabled: bool = true
@export var hold_offset: Vector2 = Vector2.ZERO
@export var drop_offset: Vector2 = Vector2(32, 0)

var original_parent: Node = null


func can_carry() -> bool:
	return enabled


func get_carried_root() -> Node2D:
	return owner as Node2D


func on_picked_up(actor: Node2D) -> void:
	LoggerConsole.log(str(actor.name) + " picked up " + str(owner.name))


func on_dropped(actor: Node2D) -> void:
	
	LoggerConsole.log(str(actor.name) + " dropped " + str(owner.name))
