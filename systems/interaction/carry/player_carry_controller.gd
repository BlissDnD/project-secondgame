extends Node
class_name PlayerCarryController

@export var player_body: Node2D
@export var interaction_area: Area2D
@export var placement_controller: PlacementController

@export var drop_offset: Vector2 = Vector2(32, 0)
@export var hold_offset: Vector2 = Vector2(0, -48)

@export_range(0.01, 10000.0, 0.01) var player_base_weight: float = 70.0
@export_range(0.01, 10000.0, 0.01) var lift_strength: float = 25.0
@export_range(0.01, 10000.0, 0.01) var carry_strength: float = 30.0
@export_range(0.01, 10000.0, 0.01) var throw_strength: float = 20.0

@export_range(0.0, 10000.0, 1.0) var base_throw_impulse: float = 650.0

@export_group("Throw Charge")
@export_range(0.05, 1.0, 0.01) var minimum_throw_power: float = 0.25
@export_range(0.1, 10.0, 0.01) var base_full_charge_time: float = 0.75
@export_range(0.1, 5.0, 0.01) var heavy_item_charge_penalty: float = 1.0

var carried_component: CarryableComponent

var _carry_collision_shapes: Array[CollisionShape2D] = []
var _is_charging_throw: bool = false
var _throw_charge: float = 0.0


func _process(delta: float) -> void:
	if carried_component != null:
		carried_component.hold_offset = hold_offset
		carried_component.carry_update()

	if _is_charging_throw:
		_update_throw_charge(delta)

	if placement_controller != null and placement_controller.is_placing:
		var target_position := _get_player_place_target_position()
		placement_controller.update_preview_from_world_position(target_position)


func try_interact() -> void:
	if placement_controller != null and placement_controller.is_placing:
		placement_controller.try_place_current()
		return

	if carried_component != null:
		cancel_throw_charge()

		if _try_insert_carried_worker_into_socket():
			_clear_carry_collision_proxy()
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
		if not carryable.can_be_lifted_by(lift_strength):
			LoggerConsole.log("Too heavy to lift: " + str(carryable.get_weight()))
			return

		if carryable.pickup(player_body):
			carried_component = carryable
			carried_component.hold_offset = hold_offset
			_create_carry_collision_proxy(carried_component)
			return


func cancel_current_action() -> void:
	if placement_controller != null and placement_controller.is_placing:
		placement_controller.cancel_placement()
		return

	if carried_component != null:
		cancel_throw_charge()
		_drop_carried()


func start_throw_charge() -> void:
	if carried_component == null:
		return

	_is_charging_throw = true
	_throw_charge = 0.0


func cancel_throw_charge() -> void:
	_is_charging_throw = false
	_throw_charge = 0.0


func release_charged_throw(direction: Vector2) -> void:
	if carried_component == null:
		cancel_throw_charge()
		return

	if direction.length() <= 0.0:
		cancel_throw_charge()
		return

	var charged_impulse := get_current_throw_impulse()

	_is_charging_throw = false
	_throw_charge = 0.0

	_throw_carried_with_impulse(direction.normalized(), charged_impulse)


func throw_carried(direction: Vector2) -> void:
	if carried_component == null:
		return

	_throw_carried_with_impulse(direction.normalized(), get_current_throw_impulse())


func is_carrying() -> bool:
	return carried_component != null


func is_charging_throw() -> bool:
	return _is_charging_throw


func get_throw_charge() -> float:
	return clampf(_throw_charge, 0.0, 1.0)


func get_current_throw_power_ratio() -> float:
	return lerpf(minimum_throw_power, 1.0, get_throw_charge())


func get_current_throw_impulse() -> float:
	return base_throw_impulse * get_current_throw_power_ratio()


func get_max_throw_velocity_for_direction(direction: Vector2) -> Vector2:
	if carried_component == null:
		return Vector2.ZERO

	if direction.length() <= 0.0:
		return Vector2.ZERO

	var weight := maxf(carried_component.get_weight(), 0.01)
	var throw_multiplier := carried_component.get_throw_multiplier(throw_strength)
	var throw_impulse := (
		direction.normalized()
		* base_throw_impulse
		* throw_multiplier
	)

	var throw_velocity := throw_impulse / weight

	return throw_velocity + _get_player_velocity()


func get_current_throw_velocity_for_direction(direction: Vector2) -> Vector2:
	if carried_component == null:
		return Vector2.ZERO

	if direction.length() <= 0.0:
		return Vector2.ZERO

	var weight := maxf(carried_component.get_weight(), 0.01)
	var throw_multiplier := carried_component.get_throw_multiplier(throw_strength)
	var throw_impulse := (
		direction.normalized()
		* get_current_throw_impulse()
		* throw_multiplier
	)

	var throw_velocity := throw_impulse / weight

	return throw_velocity + _get_player_velocity()

func get_carried_weight() -> float:
	if carried_component == null:
		return 0.0

	return carried_component.get_weight()


func get_effective_player_weight() -> float:
	return player_base_weight + get_carried_weight()


func get_movement_speed_multiplier() -> float:
	if carried_component == null:
		return 1.0

	return carried_component.get_carry_speed_multiplier(carry_strength)


func _update_throw_charge(delta: float) -> void:
	if carried_component == null:
		cancel_throw_charge()
		return

	var weight := maxf(carried_component.get_weight(), 0.01)
	var strength_ratio := throw_strength / (throw_strength + weight * heavy_item_charge_penalty)
	var charge_time := base_full_charge_time / maxf(strength_ratio, 0.05)

	_throw_charge = clampf(_throw_charge + delta / charge_time, 0.0, 1.0)


func _throw_carried_with_impulse(direction: Vector2, throw_impulse: float) -> void:
	if carried_component == null:
		return

	_clear_carry_collision_proxy()

	var throw_position := player_body.global_position + hold_offset
	var inherited_velocity := _get_player_velocity()

	carried_component.throw_from(
		throw_position,
		direction,
		throw_impulse,
		throw_strength,
		inherited_velocity
	)

	carried_component = null


func _drop_carried() -> void:
	if carried_component == null:
		return

	_clear_carry_collision_proxy()

	var drop_position := player_body.global_position + drop_offset
	var inherited_velocity := _get_player_velocity()

	carried_component.drop(drop_position, inherited_velocity)
	carried_component = null


func _create_carry_collision_proxy(carryable: CarryableComponent) -> void:
	_clear_carry_collision_proxy()

	if player_body == null:
		return

	var player_collision_object := player_body as CollisionObject2D
	if player_collision_object == null:
		return

	var source_shapes := carryable.get_collision_shapes_for_proxy()

	for source_shape in source_shapes:
		if source_shape == null or source_shape.shape == null:
			continue

		var proxy_shape := CollisionShape2D.new()
		proxy_shape.name = "CarryCollisionProxy"
		proxy_shape.shape = source_shape.shape.duplicate(true)
		proxy_shape.position = hold_offset + source_shape.position
		proxy_shape.rotation = source_shape.rotation
		proxy_shape.scale = source_shape.scale
		proxy_shape.disabled = false

		player_collision_object.add_child(proxy_shape)
		_carry_collision_shapes.append(proxy_shape)


func _clear_carry_collision_proxy() -> void:
	for shape in _carry_collision_shapes:
		if is_instance_valid(shape):
			shape.queue_free()

	_carry_collision_shapes.clear()


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

	_clear_carry_collision_proxy()

	carried_component.is_carried = false
	carried_component.carrier = null

	return socket.insert_worker(worker)


func _find_nearest_carryable() -> CarryableComponent:
	var best: CarryableComponent = null
	var best_distance := INF

	if interaction_area == null or player_body == null:
		return null

	for area in interaction_area.get_overlapping_areas():
		if area is CarryableComponent:
			var carryable := area as CarryableComponent

			if not carryable.can_carry():
				continue

			var distance := player_body.global_position.distance_to(carryable.global_position)

			if distance < best_distance:
				best_distance = distance
				best = carryable

	return best


func _find_nearest_placeable_pickup() -> PlaceablePickupComponent:
	var best: PlaceablePickupComponent = null
	var best_distance := INF

	if interaction_area == null or player_body == null:
		return null

	for area in interaction_area.get_overlapping_areas():
		if area is PlaceablePickupComponent:
			var pickup := area as PlaceablePickupComponent
			var distance := player_body.global_position.distance_to(pickup.global_position)

			if distance < best_distance:
				best_distance = distance
				best = pickup

	return best


func _find_nearest_worker_socket() -> WorkerSocket:
	var best: WorkerSocket = null
	var best_distance := INF

	if interaction_area == null or player_body == null:
		return null

	for area in interaction_area.get_overlapping_areas():
		if area is WorkerSocket:
			var socket := area as WorkerSocket
			var distance := player_body.global_position.distance_to(socket.global_position)

			if distance < best_distance:
				best_distance = distance
				best = socket

	return best


func _get_player_place_target_position() -> Vector2:
	var facing := 1.0

	if player_body != null and player_body.has_method("get_facing_direction"):
		facing = float(player_body.get_facing_direction())

	return player_body.global_position + Vector2(48.0 * facing, 0.0)


func _get_player_velocity() -> Vector2:
	var character := player_body as CharacterBody2D
	if character != null:
		return character.velocity

	return Vector2.ZERO
