class_name SimulationZone
extends RefCounted

var zone_id: Vector2i
var world_rect: Rect2
var is_active: bool = false

var last_simulated_world_minute: int = 0
var objects: Array[Node] = []


func _init(
	p_zone_id: Vector2i,
	p_world_rect: Rect2
) -> void:
	zone_id = p_zone_id
	world_rect = p_world_rect


func contains_world_position(world_position: Vector2) -> bool:
	return world_rect.has_point(world_position)


func add_object(object: Node) -> void:
	if object == null:
		return

	if objects.has(object):
		return

	objects.append(object)


func remove_object(object: Node) -> void:
	objects.erase(object)


func get_elapsed_minutes_since_last_simulation(current_world_minute: int) -> int:
	return max(current_world_minute - last_simulated_world_minute, 0)


func mark_simulated(current_world_minute: int) -> void:
	last_simulated_world_minute = current_world_minute
