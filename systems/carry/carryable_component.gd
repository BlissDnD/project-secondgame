extends Node
class_name CarryableComponent

@export var enabled: bool = true

@export_group("Carry")
@export var hold_offset: Vector2 = Vector2.ZERO

@export_group("Placement")
@export var requires_ground: bool = true
@export var footprint_tiles: Vector2i = Vector2i(1, 1)
@export var allowed_terrain_types: Array[StringName] = [&"dirt"]

var original_parent: Node = null


func can_carry() -> bool:
	return enabled


func get_carried_root() -> Node2D:
	return owner as Node2D


func on_picked_up(actor: Node2D) -> void:
	LoggerConsole.log(str(actor.name) + " picked up " + str(owner.name))


func on_dropped(actor: Node2D) -> void:
	LoggerConsole.log(str(actor.name) + " dropped " + str(owner.name))


func on_placed(actor: Node2D) -> void:
	LoggerConsole.log(str(actor.name) + " placed " + str(owner.name))
