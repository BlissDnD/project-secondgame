
extends Node

@export var zone_size: Vector2 = Vector2(1024.0, 1024.0)

var _zones: Dictionary = {}


func get_or_create_zone_for_world_position(world_position: Vector2) -> SimulationZone:
	var zone_id := get_zone_id_for_world_position(world_position)

	if _zones.has(zone_id):
		return _zones[zone_id]

	var zone := _create_zone(zone_id)
	_zones[zone_id] = zone

	return zone


func get_zone_for_world_position(world_position: Vector2) -> SimulationZone:
	var zone_id := get_zone_id_for_world_position(world_position)

	if not _zones.has(zone_id):
		return null

	return _zones[zone_id]


func get_zone_id_for_world_position(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / zone_size.x),
		floori(world_position.y / zone_size.y)
	)


func register_object(object: Node2D) -> void:
	if object == null:
		return

	var zone := get_or_create_zone_for_world_position(object.global_position)
	zone.add_object(object)


func unregister_object(object: Node2D) -> void:
	if object == null:
		return

	var zone := get_zone_for_world_position(object.global_position)

	if zone == null:
		return

	zone.remove_object(object)


func get_zones_in_radius(world_position: Vector2, radius_in_zones: int) -> Array[SimulationZone]:
	var center_id := get_zone_id_for_world_position(world_position)
	var result: Array[SimulationZone] = []

	for x in range(center_id.x - radius_in_zones, center_id.x + radius_in_zones + 1):
		for y in range(center_id.y - radius_in_zones, center_id.y + radius_in_zones + 1):
			var zone_id := Vector2i(x, y)

			if not _zones.has(zone_id):
				_zones[zone_id] = _create_zone(zone_id)

			result.append(_zones[zone_id])

	return result


func get_all_zones() -> Array[SimulationZone]:
	var result: Array[SimulationZone] = []

	for zone in _zones.values():
		result.append(zone)

	return result


func _create_zone(zone_id: Vector2i) -> SimulationZone:
	var world_rect := Rect2(
		Vector2(zone_id.x * zone_size.x, zone_id.y * zone_size.y),
		zone_size
	)

	return SimulationZone.new(zone_id, world_rect)
