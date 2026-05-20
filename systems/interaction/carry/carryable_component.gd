extends Area2D
class_name CarryableComponent

signal picked_up(carrier: Node)
signal dropped(carrier: Node)

@export var root_node: Node2D

@export var hold_offset: Vector2 = Vector2(24, -16)

@export var can_be_carried: bool = true
@export var can_drop_freely: bool = true
@export var requires_ground: bool = false

@export var supports_grid_placement: bool = false
@export var can_insert_into_worker_socket: bool = false

@export var placeable_definition: PlaceableDefinition

@export var footprint_tiles: Vector2i = Vector2i.ONE

@export var disable_body_collision_while_carried: bool = true
@export var enable_body_collision_when_dropped: bool = true
@export var enable_body_collision_when_placed: bool = true

@export var ground_anchor: Node2D

var carrier: Node2D = null
var is_carried: bool = false

var original_parent: Node = null


func _ready() -> void:
	if root_node == null:
		root_node = owner as Node2D


func can_carry() -> bool:
	return can_be_carried


func get_carried_root() -> Node2D:
	return root_node


func pickup(new_carrier: Node2D) -> bool:
	if not can_be_carried:
		return false

	if root_node == null:
		return false

	carrier = new_carrier
	is_carried = true

	if root_node.has_method("on_picked_up"):
		root_node.on_picked_up()

	picked_up.emit(carrier)

	return true


func drop(drop_position: Vector2) -> void:
	if root_node == null:
		return

	root_node.global_position = drop_position

	var old_carrier := carrier

	carrier = null
	is_carried = false

	if root_node.has_method("on_dropped"):
		root_node.on_dropped()

	dropped.emit(old_carrier)


func carry_update() -> void:
	if not is_carried:
		return

	if carrier == null:
		return

	if root_node == null:
		return

	root_node.global_position = carrier.global_position + hold_offset


func on_picked_up(by_actor: Node) -> void:
	pass


func on_dropped(by_actor: Node) -> void:
	pass


func on_placed(by_actor: Node) -> void:
	pass
