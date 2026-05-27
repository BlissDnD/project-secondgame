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

var _carry_collision_shapes: Array[CollisionShape2D] = []
var _is_charging_throw: bool = false
var _throw_charge: float = 0.0
var _has_valid_context_placement: bool = false


func _ready() -> void:
	call_deferred("_resolve_placement_controller")


func _physics_process(delta: float) -> void:
	if _is_charging_throw:
		_update_throw_charge(delta)

	_update_context_placement_preview()


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


func try_interact() -> void:
	if carried_component != null:
		cancel_throw_charge()

		if _try_insert_carried_worker_into_socket():
			_clear_carry_collision_proxy()
			carried_component = null
			_cancel_placement_preview()
			return

		if _try_context_place_carried():
			_clear_carry_collision_proxy()
			carried_component = null
			return

		_drop_carried()
		return

	var carryable := _find_nearest_carryable()

	if carryable != null:
		if not carryable.can_be_lifted_by(lift_strength):
			LoggerConsole.log("Too heavy to lift: " + str(carryable.get_weight()))
			return

		if carryable.pickup(player_body, hold_point):
			carried_component = carryable
			_create_carry_collision_proxy(carried_component)
			return


func get_carried_carryable() -> CarryableComponent:
	return carried_component


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
		var root: Node2D = carried_component.get_carried_root()

		if root != null:
			return root.global_position

	if player_body != null:
		return player_body.global_position + hold_offset

	return Vector2.ZERO


func is_carrying() -> bool:
	return carried_component != null


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
		if not controller.is_placing:
			controller.begin_placement(definition, scene)

		controller.update_preview_from_world_position(target_position)
		_has_valid_context_placement = controller.current_valid

	if not _has_valid_context_placement:
		_cancel_placement_preview()


func _try_context_place_carried() -> bool:
	if carried_component == null:
		return false

	var controller := _get_placement_controller()

	if controller == null:
		return false

	if not carried_component.supports_placement():
		return false

	var definition := carried_component.get_placeable_definition()
	var scene := carried_component.get_placeable_scene()

	if definition == null or scene == null:
		return false

	var target_position_variant: Variant = _get_context_place_target_position_or_null(definition)

	if target_position_variant == null:
		return false

	var target_position: Vector2 = target_position_variant as Vector2

	var valid := false

	if controller.has_method("update_context_preview"):
		valid = controller.update_context_preview(
			definition,
			scene,
			target_position
		)
	else:
		if not controller.is_placing:
			controller.begin_placement(definition, scene)

		controller.update_preview_from_world_position(target_position)
		valid = controller.current_valid

	if not valid:
		return false

	var placed := controller.try_place_current()

	if placed == null:
		return false

	carried_component.finish_after_successful_place()
	_cancel_placement_preview()

	return true


func _get_context_place_target_position_or_null(definition: PlaceableDefinition) -> Variant:
	if definition == null:
		return null

	if not definition.use_context_placement:
		return null

	if definition.context_required_group == &"":
		return null

	var context_node := _find_nearest_context_node(
		definition.context_required_group,
		definition.context_required_radius
	)

	if context_node == null:
		return null

	var context_cell := _world_to_context_cell(
		context_node.global_position,
		definition.context_cell_size
	)

	var target_cell := context_cell + definition.context_side_offset_cells

	return _context_cell_to_world(
		target_cell,
		definition.context_cell_size
	)


func _find_nearest_context_node(group_name: StringName, max_distance: float) -> Node2D:
	if player_body == null:
		return null

	var nodes := get_tree().get_nodes_in_group(group_name)
	var best: Node2D = null
	var best_distance := INF

	for node in nodes:
		var node_2d := node as Node2D

		if node_2d == null:
			continue

		var distance := player_body.global_position.distance_to(node_2d.global_position)

		if distance > max_distance:
			continue

		if distance < best_distance:
			best_distance = distance
			best = node_2d

	return best


func _world_to_context_cell(world_position: Vector2, local_cell_size: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / local_cell_size.x),
		floori(world_position.y / local_cell_size.y)
	)


func _context_cell_to_world(cell: Vector2i, local_cell_size: Vector2) -> Vector2:
	return Vector2(
		cell.x * local_cell_size.x,
		cell.y * local_cell_size.y
	)


func _cancel_placement_preview() -> void:
	var controller := _get_placement_controller()

	if controller == null:
		return

	if controller.is_placing:
		controller.cancel_placement()


func _throw_carried_with_impulse(direction: Vector2, throw_impulse: float) -> void:
	if carried_component == null:
		return

	_clear_carry_collision_proxy()
	_cancel_placement_preview()

	var throw_position := get_throw_origin()
	var player_physics_body := player_body as PhysicsBody2D
	var throw_velocity := _get_throw_velocity_for_direction(direction, throw_impulse)

	LoggerConsole.log(
		"THROW "
		+ str(carried_component.name)
		+ " weight="
		+ str(carried_component.get_weight())
		+ " gravity="
		+ str(carried_component.get_throw_gravity())
		+ " velocity="
		+ str(throw_velocity)
	)

	carried_component.throw_with_velocity(
		throw_position,
		throw_velocity,
		player_physics_body
	)

	carried_component = null


func _get_throw_velocity_for_direction(direction: Vector2, throw_impulse: float) -> Vector2:
	if carried_component == null:
		return Vector2.ZERO

	var weight := maxf(carried_component.get_weight(), 0.01)
	var throw_multiplier := carried_component.get_throw_multiplier(throw_strength)

	var local_throw_velocity := (
		direction.normalized()
		* throw_impulse
		* throw_multiplier
	) / weight

	var max_speed := carried_component.get_max_throw_speed()

	if local_throw_velocity.length() > max_speed:
		local_throw_velocity = local_throw_velocity.normalized() * max_speed

	return local_throw_velocity + _get_player_velocity()


func _drop_carried() -> void:
	if carried_component == null:
		return

	if not carried_component.can_drop_freely():
		print("DROP BLOCKED: carried item cannot drop freely")
		return

	_clear_carry_collision_proxy()
	_cancel_placement_preview()

	var drop_position := _get_player_place_target_position()
	var inherited_velocity := _get_player_velocity()

	carried_component.drop(drop_position, inherited_velocity)
	carried_component = null


func _create_carry_collision_proxy(carryable: CarryableComponent) -> void:
	_clear_carry_collision_proxy()

	var player_collision_object := player_body as CollisionObject2D

	if player_collision_object == null:
		return

	for source_shape in carryable.get_collision_shapes_for_proxy():
		if source_shape == null or source_shape.shape == null:
			continue

		var proxy_shape := CollisionShape2D.new()
		proxy_shape.name = "CarryCollisionProxy"
		proxy_shape.shape = source_shape.shape.duplicate(true)
		proxy_shape.position = hold_offset + source_shape.position
		proxy_shape.rotation = 0.0
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

	if not carried_component.can_insert_into_worker_socket():
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
	_cancel_placement_preview()

	carried_component.force_drop(worker.global_position, Vector2.ZERO)
	carried_component = null

	return socket.insert_worker(worker)


func _find_nearest_carryable() -> CarryableComponent:
	var best: CarryableComponent = null
	var best_distance := INF

	if interaction_area == null or player_body == null:
		return null

	for area in interaction_area.get_overlapping_areas():
		var carryable := _find_carryable_from_area(area)

		if carryable == null:
			continue

		if not carryable.can_carry():
			continue

		var root: Node2D = carryable.get_carried_root()

		if root == null:
			continue

		var distance := player_body.global_position.distance_to(root.global_position)

		if distance < best_distance:
			best_distance = distance
			best = carryable

	return best


func _find_carryable_from_area(area: Area2D) -> CarryableComponent:
	if area == null:
		return null

	if area is CarryableComponent:
		return area as CarryableComponent

	var root := area.owner

	if root == null:
		root = area

	return _find_carryable_component_recursive(root)


func _find_carryable_component_recursive(node: Node) -> CarryableComponent:
	if node == null:
		return null

	if node is CarryableComponent:
		return node as CarryableComponent

	for child in node.get_children():
		var found := _find_carryable_component_recursive(child)

		if found != null:
			return found

	return null


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

	if player_body == null:
		return Vector2.ZERO

	return player_body.global_position + Vector2(48.0 * facing, 0.0)


func _get_player_velocity() -> Vector2:
	var character := player_body as CharacterBody2D

	if character != null:
		return character.velocity

	return Vector2.ZERO
