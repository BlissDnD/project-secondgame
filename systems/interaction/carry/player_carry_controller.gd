extends Node
class_name PlayerCarryController

@export var player_body: Node2D
@export var interaction_area: Area2D
@export var placement_controller: PlacementController

@export var drop_offset: Vector2 = Vector2(32, 0)

var carried_component: CarryableComponent


func _process(_delta: float) -> void:
	if carried_component != null:
		carried_component.carry_update()

	if placement_controller != null and placement_controller.is_placing:
		var target_position := _get_player_place_target_position()
		placement_controller.update_preview_from_world_position(target_position)


func try_interact() -> void:
	if placement_controller != null and placement_controller.is_placing:
		placement_controller.try_place_current()
		return

	if carried_component != null:
		if _try_insert_carried_worker_into_socket():
			carried_component = null
			return

		_drop_carried()
		return

	var placeable_pickup := _find_nearest_placeable_pickup()
	if placeable_pickup != null:
		if placeable_pickup.pickup_for_placement(placement_controller):
			return

	var carryable := _find_nearest_carryable()
	if carryable != null:
		if carryable.pickup(player_body):
			carried_component = carryable
			return


func cancel_current_action() -> void:
	if placement_controller != null and placement_controller.is_placing:
		placement_controller.cancel_placement()
		return

	if carried_component != null:
		_drop_carried()


func _drop_carried() -> void:
	if carried_component == null:
		return

	var drop_position := player_body.global_position + drop_offset
	carried_component.drop(drop_position)
	carried_component = null


func _try_insert_carried_worker_into_socket() -> bool:
	if carried_component == null:
		return false

	var worker := carried_component.root_node
	if worker == null:
		return false

	var socket := _find_nearest_worker_socket()
	if socket == null:
		return false

	if not socket.can_accept_worker(worker):
		return false

	carried_component.is_carried = false
	carried_component.carrier = null
	carried_component = null

	return socket.insert_worker(worker)


func _find_nearest_carryable() -> CarryableComponent:
	var best: CarryableComponent = null
	var best_distance := INF

	for area in interaction_area.get_overlapping_areas():
		if area is CarryableComponent:
			var distance := player_body.global_position.distance_to(area.global_position)
			if distance < best_distance:
				best_distance = distance
				best = area

	return best


func _find_nearest_placeable_pickup() -> PlaceablePickupComponent:
	var best: PlaceablePickupComponent = null
	var best_distance := INF

	for area in interaction_area.get_overlapping_areas():
		if area is PlaceablePickupComponent:
			var distance := player_body.global_position.distance_to(area.global_position)
			if distance < best_distance:
				best_distance = distance
				best = area

	return best


func _find_nearest_worker_socket() -> WorkerSocket:
	var best: WorkerSocket = null
	var best_distance := INF

	for area in interaction_area.get_overlapping_areas():
		if area is WorkerSocket:
			var distance := player_body.global_position.distance_to(area.global_position)
			if distance < best_distance:
				best_distance = distance
				best = area

	return best


func _get_player_place_target_position() -> Vector2:
	var facing := 1.0

	if player_body.has_method("get_facing_direction"):
		facing = player_body.get_facing_direction()

	return player_body.global_position + Vector2(48.0 * facing, 0.0)
