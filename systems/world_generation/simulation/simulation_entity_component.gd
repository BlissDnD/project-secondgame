class_name SimulationEntityComponent
extends Node

signal simulation_activated
signal simulation_deactivated

@export var entity_root: Node2D
@export var active_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
@export var dormant_process_mode: Node.ProcessMode = Node.PROCESS_MODE_DISABLED

var current_zone_id: Vector2i
var is_simulation_active: bool = true


func _ready() -> void:
	call_deferred("_initialize")


func _exit_tree() -> void:
	_unregister_from_zone()


func _initialize() -> void:
	if entity_root == null:
		entity_root = owner as Node2D

	if entity_root == null:
		push_error("SimulationEntityComponent missing entity_root.")
		return

	_register_to_zone()


func refresh_zone_registration() -> void:
	if entity_root == null:
		return

	_unregister_from_zone()
	_register_to_zone()


func set_simulation_active(active: bool) -> void:
	if is_simulation_active == active:
		return

	is_simulation_active = active

	if entity_root != null:
		entity_root.process_mode = active_process_mode if active else dormant_process_mode

	if active:
		simulation_activated.emit()
	else:
		simulation_deactivated.emit()


func _register_to_zone() -> void:
	var zone_registry := get_node_or_null("/root/SimulationZoneRegistry")

	if zone_registry == null:
		push_error("SimulationEntityComponent missing SimulationZoneRegistry autoload.")
		return

	var zone = zone_registry.call(
		"get_or_create_zone_for_world_position",
		entity_root.global_position
	)

	zone.add_object(entity_root)
	current_zone_id = zone.zone_id


func _unregister_from_zone() -> void:
	if entity_root == null:
		return

	var zone_registry := get_node_or_null("/root/SimulationZoneRegistry")

	if zone_registry == null:
		return

	zone_registry.call("unregister_object", entity_root)
