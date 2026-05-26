extends Area2D
class_name CarryableComponent

signal picked_up(carrier: Node2D)
signal dropped(carrier: Node2D)
signal thrown(carrier: Node2D, velocity: Vector2)
signal placed(carrier: Node2D, placed_node: Node)

@export var root_node: Node2D
@export var hold_offset: Vector2 = Vector2(0, -48)

@export var carry_profile: CarryProfile

@export_group("Optional Placement Override")
@export var supports_grid_placement: bool = false
@export var placeable_definition: PlaceableDefinition
@export var placeable_scene: PackedScene

@export var disable_body_collision_while_carried: bool = true
@export var enable_body_collision_when_dropped: bool = true
@export var enable_body_collision_when_placed: bool = true

@export var ground_anchor: Node2D

@export_group("Highlight")
@export var highlight_target: CanvasItem
@export var highlight_color: Color = Color(1.35, 1.35, 1.35, 1.0)

var carrier: Node2D = null
var is_carried: bool = false
var original_parent: Node = null

var _default_modulate: Color = Color.WHITE
var _is_highlighted: bool = false
var _original_global_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if root_node == null:
		root_node = owner as Node2D

	if highlight_target == null:
		highlight_target = _find_first_canvas_item(root_node)

	if highlight_target != null:
		_default_modulate = highlight_target.modulate


func can_carry() -> bool:
	if carry_profile == null:
		return false

	return carry_profile.can_be_carried and root_node != null


func can_be_lifted_by(lift_strength: float) -> bool:
	if not can_carry():
		return false

	return get_weight() <= lift_strength


func can_be_thrown() -> bool:
	if carry_profile == null:
		return false

	return carry_profile.can_be_thrown


func can_drop_freely() -> bool:
	if carry_profile == null:
		return true

	return carry_profile.can_drop_freely


func supports_placement() -> bool:
	return supports_grid_placement \
		and placeable_definition != null \
		and placeable_scene != null


func update_placement_preview(
	placement_controller: PlacementController,
	world_position: Vector2
) -> bool:
	if placement_controller == null:
		return false

	if not supports_placement():
		placement_controller.cancel_placement()
		return false

	if not is_carried:
		placement_controller.cancel_placement()
		return false

	if not placement_controller.is_placing:
		placement_controller.begin_placement(placeable_definition, placeable_scene)

	placement_controller.update_preview_from_world_position(world_position)

	return placement_controller.current_valid


func clear_placement_preview(placement_controller: PlacementController) -> void:
	if placement_controller == null:
		return

	if placement_controller.is_placing:
		placement_controller.cancel_placement()


func try_place_with_controller(
	placement_controller: PlacementController,
	world_position: Vector2
) -> bool:
	if placement_controller == null:
		return false

	if not supports_placement():
		return false

	if not is_carried:
		return false

	update_placement_preview(placement_controller, world_position)

	if not placement_controller.current_valid:
		return false

	var old_carrier := carrier
	var placed_node := placement_controller.try_place_current()

	if placed_node == null:
		return false

	_finish_carried_without_world_drop()

	if root_node != null:
		root_node.queue_free()

	placed.emit(old_carrier, placed_node)
	return true


func can_insert_into_worker_socket() -> bool:
	if carry_profile == null:
		return false

	return carry_profile.can_insert_into_worker_socket


func get_motion_profile() -> PhysicalMotionProfile:
	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		return physical_body.get_motion_profile()

	var external_motion := _find_external_motion_component()
	if external_motion != null:
		return external_motion.get_motion_profile()

	return null


func get_weight() -> float:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.weight

	return 0.0


func get_throw_gravity() -> Vector2:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.get_gravity()

	var gravity_value := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var gravity_vector := ProjectSettings.get_setting("physics/2d/default_gravity_vector") as Vector2

	return gravity_vector.normalized() * gravity_value


func get_max_throw_speed() -> float:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.max_throw_speed

	return 2200.0


func apply_motion_damping(velocity: Vector2, delta: float) -> Vector2:
	var motion_profile := get_motion_profile()

	if motion_profile == null:
		return velocity

	return motion_profile.apply_linear_damping(velocity, delta)


func get_carry_speed_multiplier(carry_strength: float) -> float:
	if carry_profile == null:
		return 1.0

	var weight := get_weight()

	if weight <= carry_profile.comfortable_weight_limit:
		return 1.0

	var overload := weight - carry_profile.comfortable_weight_limit
	var penalty := overload / maxf(carry_strength, 0.01)

	return clampf(1.0 - penalty, 0.25, 1.0)


func get_throw_multiplier(throw_strength: float) -> float:
	if carry_profile == null:
		return 0.0

	if not carry_profile.can_be_thrown:
		return 0.0

	var weight := get_weight()
	var strength_base := maxf(throw_strength, 0.01)
	var mass_factor := strength_base / (strength_base + weight)

	return clampf(mass_factor * carry_profile.throw_efficiency, 0.0, 1.0)


func get_carried_root() -> Node2D:
	return root_node


func pickup(new_carrier: Node2D, hold_parent: Node2D = null) -> bool:
	if not can_carry():
		return false

	_release_placement_occupancy_if_needed()

	original_parent = root_node.get_parent()
	_original_global_scale = root_node.global_scale

	carrier = new_carrier
	is_carried = true

	set_highlighted(false)
	_set_physics_carried_state(true)
	_reset_rotation_for_carry()
	_notify_external_motion_begin_carried()

	if hold_parent != null:
		root_node.reparent(hold_parent, false)
		root_node.position = Vector2.ZERO
		root_node.global_scale = _original_global_scale
		root_node.rotation = 0.0
	else:
		root_node.global_position = carrier.global_position + hold_offset
		root_node.global_scale = _original_global_scale

	if root_node.has_method("on_picked_up"):
		root_node.on_picked_up()

	picked_up.emit(carrier)
	return true


func drop(drop_position: Vector2, inherited_velocity: Vector2 = Vector2.ZERO) -> void:
	_drop_internal(drop_position, inherited_velocity, true, true)


func throw_with_velocity(
	throw_position: Vector2,
	throw_velocity: Vector2,
	ignored_body: PhysicsBody2D = null
) -> void:
	if not can_be_thrown():
		return

	var old_carrier := carrier

	_drop_internal(throw_position, Vector2.ZERO, false, false)

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		_apply_thrower_collision_grace(physical_body, ignored_body)
		physical_body.linear_velocity = throw_velocity
		physical_body.angular_velocity = 0.0
		thrown.emit(old_carrier, throw_velocity)
		return

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.linear_velocity = throw_velocity
		rigid_body.angular_velocity = 0.0
		thrown.emit(old_carrier, throw_velocity)
		return

	var external_motion := _find_external_motion_component()
	if external_motion != null:
		external_motion.start_external_motion(throw_velocity)

	if root_node.has_method("on_thrown"):
		root_node.on_thrown(throw_velocity)

	thrown.emit(old_carrier, throw_velocity)


func set_highlighted(value: bool) -> void:
	if _is_highlighted == value:
		return

	_is_highlighted = value

	if highlight_target == null:
		return

	highlight_target.modulate = highlight_color if value else _default_modulate


func is_highlighted() -> bool:
	return _is_highlighted


func get_collision_shapes_for_proxy() -> Array[CollisionShape2D]:
	var result: Array[CollisionShape2D] = []

	if root_node == null:
		return result

	_collect_collision_shapes(root_node, result)
	return result


func _drop_internal(
	drop_position: Vector2,
	inherited_velocity: Vector2,
	end_external_carried_state: bool,
	emit_drop_lifecycle: bool
) -> void:
	if root_node == null:
		return

	if original_parent != null:
		var previous_global := root_node.global_position

		if root_node.get_parent() != null:
			root_node.get_parent().remove_child(root_node)

		original_parent.add_child(root_node)
		root_node.global_position = previous_global
		root_node.global_scale = _original_global_scale

	root_node.global_position = drop_position

	var old_carrier := carrier
	carrier = null
	is_carried = false

	_set_physics_carried_state(false)

	if end_external_carried_state:
		_notify_external_motion_end_carried()

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		physical_body.linear_velocity = inherited_velocity

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.linear_velocity = inherited_velocity

	if emit_drop_lifecycle:
		if root_node.has_method("on_dropped"):
			root_node.on_dropped()

		dropped.emit(old_carrier)


func _finish_carried_without_world_drop() -> void:
	if root_node == null:
		return

	var old_carrier := carrier

	carrier = null
	is_carried = false

	_set_physics_carried_state(false)
	_notify_external_motion_end_carried()

	if root_node.has_method("on_dropped"):
		root_node.on_dropped()

	dropped.emit(old_carrier)


func _release_placement_occupancy_if_needed() -> void:
	if root_node == null:
		return

	if root_node is PlaceableObject:
		var placeable := root_node as PlaceableObject

		if "occupied_cells" in placeable:
			PlacementOccupancyRegistry.release_cells(
				placeable.occupied_cells,
				placeable
			)


func _set_physics_carried_state(value: bool) -> void:
	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		physical_body.set_carried_state(value)

		if disable_body_collision_while_carried:
			physical_body.set_body_collision_enabled(not value)

		if not value and enable_body_collision_when_dropped:
			physical_body.set_body_collision_enabled(true)

		if not value and enable_body_collision_when_placed:
			physical_body.set_body_collision_enabled(true)

		return

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.freeze = value

		if value:
			rigid_body.linear_velocity = Vector2.ZERO
			rigid_body.angular_velocity = 0.0


func _reset_rotation_for_carry() -> void:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		if motion_profile.reset_rotation_on_pickup:
			root_node.rotation = motion_profile.carried_rotation
		return

	root_node.rotation = 0.0


func _apply_thrower_collision_grace(
	physical_body: PhysicalItemBody,
	ignored_body: PhysicsBody2D
) -> void:
	if ignored_body == null:
		return

	var duration := physical_body.get_thrower_collision_grace_time()
	physical_body.temporarily_ignore_body(ignored_body, duration)


func _notify_external_motion_begin_carried() -> void:
	var external_motion := _find_external_motion_component()

	if external_motion != null:
		external_motion.begin_carried()


func _notify_external_motion_end_carried() -> void:
	var external_motion := _find_external_motion_component()

	if external_motion != null:
		external_motion.end_carried()


func _find_external_motion_component() -> WorkerExternalMotionComponent:
	if root_node == null:
		return null

	return _find_external_motion_component_recursive(root_node)


func _find_external_motion_component_recursive(node: Node) -> WorkerExternalMotionComponent:
	if node == null:
		return null

	if node is WorkerExternalMotionComponent:
		return node as WorkerExternalMotionComponent

	for child in node.get_children():
		var found := _find_external_motion_component_recursive(child)

		if found != null:
			return found

	return null


func _collect_collision_shapes(node: Node, result: Array[CollisionShape2D]) -> void:
	for child in node.get_children():
		if child is CarryableComponent:
			continue

		if child is CollisionShape2D:
			var shape_node := child as CollisionShape2D
			if shape_node.shape != null:
				result.append(shape_node)

		_collect_collision_shapes(child, result)


func _find_first_canvas_item(node: Node) -> CanvasItem:
	if node == null:
		return null

	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child as CanvasItem

	for child in node.get_children():
		if child is Sprite2D:
			return child as CanvasItem

	for child in node.get_children():
		if child is CanvasItem:
			return child as CanvasItem

	for child in node.get_children():
		var found := _find_first_canvas_item(child)

		if found != null:
			return found

	return null
