extends Node
class_name CarryableComponent

@export var enabled: bool = true

@export_group("Carry")
@export var hold_offset: Vector2 = Vector2.ZERO

@export_group("Placement")
@export var requires_ground: bool = true
@export var footprint_tiles: Vector2i = Vector2i(1, 1)
@export var allowed_terrain_types: Array[StringName] = [&"dirt"]
@export var can_drop_freely: bool = true
@export var place_offset: Vector2 = Vector2.ZERO
@export var disable_body_collision_while_carried: bool = true
@export var enable_body_collision_when_dropped: bool = true
@export var enable_body_collision_when_placed: bool = false
@export var ground_anchor: Node2D

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
