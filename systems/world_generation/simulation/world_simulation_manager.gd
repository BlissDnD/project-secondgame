extends Node

signal zone_became_active(zone)
signal zone_became_inactive(zone)

@export_node_path("Node2D") var player_path: NodePath
@export_range(0, 5, 1) var active_zone_radius: int = 1

var _player: Node2D
var _active_zones: Dictionary = {}


func _ready() -> void:
	call_deferred("_initialize")


func _process(_delta: float) -> void:
	if _player == null:
		return

	_update_active_zones()


func _initialize() -> void:
	if player_path.is_empty():
		push_error("WorldSimulationManager missing player_path.")
		return

	_player = get_node_or_null(player_path) as Node2D

	if _player == null:
		push_error("WorldSimulationManager could not resolve player.")
		return

	_update_active_zones()


func is_zone_active(zone) -> bool:
	if zone == null:
		return false

	return _active_zones.has(zone.zone_id)


func get_active_zones() -> Array:
	var result: Array = []

	for zone in _active_zones.values():
		result.append(zone)

	return result


func _update_active_zones() -> void:
	var zone_registry := get_node_or_null("/root/SimulationZoneRegistry")

	if zone_registry == null:
		push_error("WorldSimulationManager missing SimulationZoneRegistry autoload.")
		return

	var nearby_zones: Array = zone_registry.call(
		"get_zones_in_radius",
		_player.global_position,
		active_zone_radius
	)

	var next_active: Dictionary = {}

	for zone in nearby_zones:
		next_active[zone.zone_id] = zone

		if not _active_zones.has(zone.zone_id):
			_activate_zone(zone)

	for zone_id in _active_zones.keys():
		if not next_active.has(zone_id):
			var old_zone = _active_zones[zone_id]
			_deactivate_zone(old_zone)

	_active_zones = next_active


func _activate_zone(zone) -> void:
	zone.is_active = true

	for object in zone.objects:
		_set_object_simulation_active(object, true)

	print("Zone ACTIVE: ", zone.zone_id)

	zone_became_active.emit(zone)


func _deactivate_zone(zone) -> void:
	zone.is_active = false

	for object in zone.objects:
		_set_object_simulation_active(object, false)

	print("Zone INACTIVE: ", zone.zone_id)

	zone_became_inactive.emit(zone)


func _set_object_simulation_active(object: Node, active: bool) -> void:
	if object == null:
		return

	if not is_instance_valid(object):
		return

	var entity_component := _find_simulation_entity_component(object)

	if entity_component == null:
		return

	entity_component.set_simulation_active(active)


func _find_simulation_entity_component(object: Node) -> SimulationEntityComponent:
	for child in object.get_children():
		if child is SimulationEntityComponent:
			return child

	return null
