extends Node
class_name PlayerCarryController

@export var player_body: Node2D
@export var interaction_area: Area2D
@export var placement_controller: PlacementController
@export var hold_point: Node2D

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

@export_group("Mouse Throw Targeting")
@export_range(16.0, 4000.0, 1.0) var mouse_distance_for_max_power: float = 900.0
@export_range(0.0, 512.0, 1.0) var mouse_distance_dead_zone: float = 32.0

var carried_component: CarryableComponent = null

var _is_charging_throw: bool = false
var _throw_charge: float = 0.0
var _has_valid_context_placement: bool = false


func _ready() -> void:
	call_deferred("_resolve_placement_controller")


func _physics_process(delta: float) -> void:
	if _is_charging_throw:
		_update_throw_charge(delta)

	_update_context_placement_preview()


func try_interact() -> void:
	if carried_component != null:
		cancel_throw_charge()

		if _try_insert_carried_worker_into_socket():
			carried_component = null
			_cancel_placement_preview()
			return

		if _try_context_place_carried():
			carried_component = null
			return

		_drop_carried()
		return

	var carryable := _find_nearest_carryable()

	if carryable == null:
		return

	if not carryable.can_be_lifted_by(lift_strength):
		LoggerConsole.log("Too heavy to lift: " + str(carryable.get_weight()))
		return

	if carryable.pickup(player_body, hold_point):
		carried_component = carryable


func get_carried_carryable() -> CarryableComponent:
	return carried_component


func is_carrying() -> bool:
	return carried_component != null


func start_throw_charge() -> void:
	if carried_component == null:
		return

	if not carried_component.can_be_thrown():
		return

	_is_charging_throw = true
	_throw_charge = 0.0


func cancel_throw_charge() -> void:
	_is_charging_throw = false
	_throw_charge = 0.0


func release_charged_throw(direction: Vector2, mouse_position: Vector2) -> void:
	if carried_component == null:
		cancel_throw_charge()
		return

	if not carried_component.can_be_thrown():
		cancel_throw_charge()
		return

	_cancel_placement_preview()

	var power_ratio := get_current_throw_power_ratio_for_mouse(mouse_position)
	var charged_impulse := base_throw_impulse * power_ratio

	_is_charging_throw = false
	_throw_charge = 0.0

	_throw_carried_with_impulse(direction.normalized(), charged_impulse)


func get_throw_origin() -> Vector2:
	if carried_component != null:
		var root := carried_component.get_carried_root()

		if root != null:
			return root.global_position

	if player_body != null:
		return player_body.global_position + hold_offset

	return Vector2.ZERO


func is_charging_throw() -> bool:
	return _is_charging_throw


func get_throw_charge() -> float:
	return clampf(_throw_charge, 0.0, 1.0)


func get_target_throw_power_ratio_for_mouse(mouse_position: Vector2) -> float:
	var origin := get_throw_origin()
	var distance := maxf(origin.distance_to(mouse_position) - mouse_distance_dead_zone, 0.0)
	var distance_ratio := clampf(distance / maxf(mouse_distance_for_max_power, 1.0), 0.0, 1.0)

	return lerpf(minimum_throw_power, 1.0, distance_ratio)


func get_current_throw_power_ratio_for_mouse(mouse_position: Vector2) -> float:
	var target_power := get_target_throw_power_ratio_for_mouse(mouse_position)

	if not _is_charging_throw:
		return target_power

	var charged_power := lerpf(minimum_throw_power, 1.0, get_throw_charge())
	return minf(charged_power, target_power)


func get_preview_throw_velocity_for_mouse(mouse_position: Vector2) -> Vector2:
	if carried_component == null:
		return Vector2.ZERO

	var origin := get_throw_origin()
	var direction := mouse_position - origin

	if direction.length() <= 1.0:
		return Vector2.ZERO

	var power_ratio := get_current_throw_power_ratio_for_mouse(mouse_position)
	var impulse := base_throw_impulse * power_ratio

	return _get_throw_velocity_for_direction(direction.normalized(), impulse)


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


func _drop_carried() -> void:
	if carried_component == null:
		return

	var drop_position := _get_drop_position()
	var inherited_velocity := _get_player_velocity()

	carried_component.drop(drop_position, inherited_velocity)

	carried_component = null
	_cancel_placement_preview()


func _throw_carried_with_impulse(direction: Vector2, impulse: float) -> void:
	if carried_component == null:
		return

	var throw_position := get_throw_origin()
	var throw_velocity := _get_throw_velocity_for_direction(direction, impulse)

	carried_component.throw_with_velocity(
		throw_position,
		throw_velocity,
		player_body as PhysicsBody2D
	)

	carried_component = null
	_cancel_placement_preview()


func _get_throw_velocity_for_direction(direction: Vector2, impulse: float) -> Vector2:
	if carried_component == null:
		return Vector2.ZERO

	var multiplier := carried_component.get_throw_multiplier(throw_strength)
	var speed := impulse * multiplier

	return direction.normalized() * speed


func _get_drop_position() -> Vector2:
	if player_body == null:
		return Vector2.ZERO

	var facing := 1.0

	if player_body.has_method("get_facing_direction"):
		facing = float(player_body.get_facing_direction())

	return player_body.global_position + Vector2(drop_offset.x * facing, drop_offset.y)


func _get_player_velocity() -> Vector2:
	var character := player_body as CharacterBody2D

	if character != null:
		return character.velocity

	return Vector2.ZERO


func _find_nearest_carryable() -> CarryableComponent:
	if interaction_area == null:
		return null

	var best: CarryableComponent = null
	var best_distance := INF

	for area in interaction_area.get_overlapping_areas():
		var carryable := _find_carryable_from_node(area)

		if carryable == null:
			continue

		if not carryable.can_carry():
			continue

		var root := carryable.get_carried_root()

		if root == null:
			continue

		var distance := player_body.global_position.distance_to(root.global_position)

		if distance < best_distance:
			best_distance = distance
			best = carryable

	for body in interaction_area.get_overlapping_bodies():
		var carryable := _find_carryable_from_node(body)

		if carryable == null:
			continue

		if not carryable.can_carry():
			continue

		var root := carryable.get_carried_root()

		if root == null:
			continue

		var distance := player_body.global_position.distance_to(root.global_position)

		if distance < best_distance:
			best_distance = distance
			best = carryable

	return best


func _find_carryable_from_node(node: Node) -> CarryableComponent:
	var current := node

	while current != null:
		if current is CarryableComponent:
			return current as CarryableComponent

		for child in current.get_children():
			if child is CarryableComponent:
				return child as CarryableComponent

		current = current.get_parent()

	return null


func _try_insert_carried_worker_into_socket() -> bool:
	if carried_component == null:
		return false

	if not carried_component.can_insert_into_worker_socket():
		return false

	var carried_root := carried_component.get_carried_root()

	if carried_root == null:
		return false

	var worker := carried_root as Worker

	if worker == null:
		return false

	var socket := _find_nearest_worker_socket()

	if socket == null:
		return false

	if not socket.has_method("insert_worker"):
		return false

	var drop_position := carried_root.global_position

	if carried_component.has_method("force_drop"):
		carried_component.force_drop(drop_position, Vector2.ZERO)
	else:
		carried_component.drop(drop_position, Vector2.ZERO)

	var inserted: bool = bool(socket.call("insert_worker", worker))

	if not inserted:
		carried_component = worker.get_node_or_null("CarryableComponent") as CarryableComponent

	return inserted


func _find_nearest_worker_socket() -> Node:
	if interaction_area == null:
		return null

	var best_socket: Node = null
	var best_distance := INF

	for area in interaction_area.get_overlapping_areas():
		var socket := _find_socket_from_node(area)

		if socket == null:
			continue

		var socket_node := socket as Node2D

		if socket_node == null:
			continue

		var distance := player_body.global_position.distance_to(socket_node.global_position)

		if distance < best_distance:
			best_distance = distance
			best_socket = socket

	return best_socket


func _find_socket_from_node(node: Node) -> Node:
	var current := node

	while current != null:
		if current.has_method("insert_worker"):
			return current

		current = current.get_parent()

	return null


func _resolve_placement_controller() -> void:
	_get_placement_controller()


func _get_placement_controller() -> PlacementController:
	if placement_controller != null:
		return placement_controller

	placement_controller = get_tree().get_first_node_in_group("placement_controller") as PlacementController

	if placement_controller != null:
		return placement_controller

	var current_scene := get_tree().current_scene

	if current_scene != null:
		placement_controller = current_scene.find_child("PlacementController", true, false) as PlacementController

	return placement_controller


func _update_context_placement_preview() -> void:
	_has_valid_context_placement = false

	var controller := _get_placement_controller()

	if controller == null:
		return

	if carried_component == null:
		_cancel_placement_preview()
		return

	if not carried_component.supports_placement():
		_cancel_placement_preview()
		return

	var definition := carried_component.get_placeable_definition()
	var scene := carried_component.get_placeable_scene()

	if definition == null or scene == null:
		_cancel_placement_preview()
		return

	var target_position_variant: Variant = _get_context_place_target_position_or_null(definition)

	if target_position_variant == null:
		_cancel_placement_preview()
		return

	var target_position: Vector2 = target_position_variant as Vector2

	if controller.has_method("update_context_preview"):
		_has_valid_context_placement = controller.update_context_preview(
			definition,
			scene,
			target_position
		)
	else:
		controller.begin_placement(definition, scene)
		controller.update_preview_from_world_position(target_position)
		_has_valid_context_placement = controller.current_valid


func _try_context_place_carried() -> bool:
	if carried_component == null:
		return false

	if not _has_valid_context_placement:
		return false

	var controller := _get_placement_controller()

	if controller == null:
		return false

	var placed_node := controller.try_place_current()

	if placed_node == null:
		return false

	carried_component.finish_after_successful_place()
	_cancel_placement_preview()

	return true


func _get_context_place_target_position_or_null(definition: PlaceableDefinition) -> Variant:
	if player_body == null:
		return null

	var facing := 1.0

	if player_body.has_method("get_facing_direction"):
		facing = float(player_body.get_facing_direction())

	var base_position := player_body.global_position + Vector2(48.0 * facing, 0.0)

	if definition == null:
		return base_position

	return base_position


func _cancel_placement_preview() -> void:
	_has_valid_context_placement = false

	var controller := _get_placement_controller()

	if controller != null and controller.is_placing:
		controller.cancel_placement()
