extends Area2D
class_name CarryableComponent

signal picked_up(carrier: Node2D)
signal dropped(carrier: Node2D)
signal thrown(carrier: Node2D, velocity: Vector2)
signal placed(carrier: Node2D, placed_node: Node)

@export var root_node: Node2D
@export var hold_offset: Vector2 = Vector2(0, -48)

@export var carry_profile: CarryProfile

@export_group("Carry Mode")
@export var use_physical_carry: bool = true
@export var physical_carry_strength: float = 45.0
@export var physical_carry_damping: float = 10.0
@export var ignore_carrier_collision_while_carried: bool = true

@export_group("Placement")
@export var supports_grid_placement: bool = false
@export var disable_body_collision_while_carried: bool = false
@export var enable_body_collision_when_dropped: bool = true
@export var enable_body_collision_when_placed: bool = true
@export var ground_anchor: Node2D

@export_group("External Motion")
@export var external_motion_component: Node

@export_group("Highlight")
@export var highlight_target: CanvasItem
@export var highlight_color: Color = Color(1.35, 1.35, 1.35, 1.0)

@export_group("Fallback Physics")
@export var fallback_weight: float = 10.0
@export var fallback_max_throw_speed: float = 2200.0

var carrier: Node2D = null
var is_carried: bool = false
var original_parent: Node = null

var _default_modulate: Color = Color.WHITE
var _is_highlighted: bool = false
var _original_global_scale: Vector2 = Vector2.ONE
var _physical_hold_parent: Node2D = null
var _ignored_carrier_body: PhysicsBody2D = null


func _ready() -> void:
	if root_node == null:
		root_node = owner as Node2D

	if external_motion_component == null and root_node != null:
		external_motion_component = root_node.get_node_or_null(
			"WorkerExternalMotionComponent"
		)

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


func can_insert_into_worker_socket() -> bool:
	if carry_profile == null:
		return false

	return carry_profile.can_insert_into_worker_socket


func supports_placement() -> bool:
	if not supports_grid_placement:
		return false

	var placeable := get_placeable_object()

	if placeable == null:
		return false

	return placeable.can_be_context_placed()


func get_placeable_definition() -> PlaceableDefinition:
	var placeable := get_placeable_object()

	if placeable == null:
		return null

	return placeable.get_placeable_definition()


func get_placeable_scene() -> PackedScene:
	var placeable := get_placeable_object()

	if placeable == null:
		return null

	return placeable.get_placeable_scene()


func get_placeable_object() -> PlaceableObject:
	if root_node == null:
		return null

	if root_node is PlaceableObject:
		return root_node as PlaceableObject

	return null


func get_carried_root() -> Node2D:
	return root_node


func get_physical_body() -> PhysicalItemBody:
	if root_node == null:
		return null

	if root_node is PhysicalItemBody:
		return root_node as PhysicalItemBody

	return _find_physical_body_recursive(root_node)


func pickup(
	new_carrier: Node2D,
	hold_parent: Node2D = null
) -> bool:
	if not can_carry():
		return false

	if root_node == null:
		return false

	_notify_external_motion_begin_carried()
	_release_placement_occupancy_if_needed()

	original_parent = root_node.get_parent()
	_original_global_scale = root_node.global_scale

	carrier = new_carrier
	is_carried = true
	_physical_hold_parent = hold_parent

	set_highlighted(false)
	_reset_rotation_for_carry()
	_set_physics_carried_state(true)

	var physical_body := get_physical_body()

	if use_physical_carry and physical_body != null and hold_parent != null:
		physical_body.set_physical_carry_target(
			hold_parent,
			hold_offset,
			physical_carry_strength,
			physical_carry_damping
		)

		_apply_carrier_collision_exception(physical_body, new_carrier)
	else:
		if hold_parent != null:
			root_node.reparent(hold_parent, false)
			root_node.position = hold_offset
			root_node.global_scale = _original_global_scale
			root_node.rotation = 0.0
		else:
			root_node.global_position = new_carrier.global_position + hold_offset
			root_node.global_scale = _original_global_scale
			root_node.rotation = 0.0

	if root_node.has_method("on_picked_up"):
		root_node.on_picked_up()

	picked_up.emit(carrier)

	return true


func drop(
	drop_position: Vector2,
	inherited_velocity: Vector2 = Vector2.ZERO
) -> void:
	if not can_drop_freely():
		print("DROP BLOCKED: carried item cannot drop freely")
		return

	_drop_internal(
		drop_position,
		inherited_velocity,
		true,
		true
	)


func force_drop(
	drop_position: Vector2,
	inherited_velocity: Vector2 = Vector2.ZERO
) -> void:
	_drop_internal(
		drop_position,
		inherited_velocity,
		true,
		true
	)


func throw_with_velocity(
	throw_position: Vector2,
	throw_velocity: Vector2,
	ignored_body: PhysicsBody2D = null
) -> void:
	if not can_be_thrown():
		return

	var old_carrier := carrier

	_drop_internal(
		throw_position,
		Vector2.ZERO,
		false,
		false
	)

	_notify_external_motion_start_throw(throw_velocity)

	var physical_body := get_physical_body()

	if physical_body != null:
		physical_body.temporarily_ignore_body(
			ignored_body,
			physical_body.get_thrower_collision_grace_time()
		)

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

	thrown.emit(old_carrier, throw_velocity)


func finish_after_successful_place() -> void:
	if root_node == null:
		return

	var old_root := root_node

	_finish_carried_without_world_drop()

	old_root.queue_free()


func get_motion_profile() -> PhysicalMotionProfile:
	var physical_body := get_physical_body()

	if physical_body != null:
		return physical_body.get_motion_profile()

	return null


func get_weight() -> float:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.weight

	return fallback_weight


func get_throw_gravity() -> Vector2:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.get_gravity()

	var gravity_value := float(
		ProjectSettings.get_setting(
			"physics/2d/default_gravity"
		)
	)

	var gravity_vector := (
		ProjectSettings.get_setting(
			"physics/2d/default_gravity_vector"
		) as Vector2
	)

	return gravity_vector.normalized() * gravity_value


func get_max_throw_speed() -> float:
	var motion_profile := get_motion_profile()

	if motion_profile != null:
		return motion_profile.max_throw_speed

	return fallback_max_throw_speed


func apply_motion_damping(
	velocity: Vector2,
	delta: float
) -> Vector2:
	var motion_profile := get_motion_profile()

	if motion_profile == null:
		return velocity

	return motion_profile.apply_linear_damping(
		velocity,
		delta
	)


func get_carry_speed_multiplier(carry_strength: float) -> float:
	if carry_profile == null:
		return 1.0

	var weight := get_weight()

	if weight <= carry_profile.comfortable_weight_limit:
		return 1.0

	var overload := weight - carry_profile.comfortable_weight_limit
	var penalty := overload / maxf(carry_strength, 0.01)

	return clampf(
		1.0 - penalty,
		0.25,
		1.0
	)


func get_throw_multiplier(throw_strength: float) -> float:
	if carry_profile == null:
		return 0.0

	if not carry_profile.can_be_thrown:
		return 0.0

	var weight := get_weight()
	var strength_base := maxf(throw_strength, 0.01)
	var mass_factor := strength_base / (strength_base + weight)

	return clampf(
		mass_factor * carry_profile.throw_efficiency,
		0.0,
		1.0
	)


func set_highlighted(value: bool) -> void:
	if _is_highlighted == value:
		return

	_is_highlighted = value

	if highlight_target == null:
		return

	highlight_target.modulate = (
		highlight_color if value
		else _default_modulate
	)


func is_highlighted() -> bool:
	return _is_highlighted


func _drop_internal(
	drop_position: Vector2,
	inherited_velocity: Vector2,
	end_external_carried_state: bool,
	emit_drop_lifecycle: bool
) -> void:
	if root_node == null:
		return

	var old_carrier := carrier
	var physical_body := get_physical_body()

	if physical_body != null:
		physical_body.clear_physical_carry_target()

	_clear_carrier_collision_exception(physical_body)

	if not (use_physical_carry and physical_body != null):
		var previous_global := root_node.global_position

		if root_node.get_parent() != null:
			root_node.get_parent().remove_child(root_node)

		if original_parent != null:
			original_parent.add_child(root_node)
		else:
			get_tree().current_scene.add_child(root_node)

		root_node.global_position = previous_global
		root_node.global_scale = _original_global_scale
		root_node.global_position = drop_position
		root_node.rotation = 0.0
	else:
		physical_body.global_position = drop_position

	carrier = null
	is_carried = false
	_physical_hold_parent = null

	if end_external_carried_state:
		_notify_external_motion_end_carried()

	_set_physics_carried_state(false)

	if physical_body != null:
		physical_body.linear_velocity = inherited_velocity

	var rigid_body := root_node as RigidBody2D

	if rigid_body != null:
		rigid_body.linear_velocity = inherited_velocity

	if emit_drop_lifecycle:
		dropped.emit(old_carrier)


func _finish_carried_without_world_drop() -> void:
	if root_node == null:
		return

	var old_carrier := carrier
	var physical_body := get_physical_body()

	if physical_body != null:
		physical_body.clear_physical_carry_target()

	_clear_carrier_collision_exception(physical_body)

	carrier = null
	is_carried = false
	_physical_hold_parent = null

	_notify_external_motion_end_carried()
	_set_physics_carried_state(false)

	dropped.emit(old_carrier)


func _release_placement_occupancy_if_needed() -> void:
	var placeable := get_placeable_object()

	if placeable == null:
		return

	PlacementOccupancyRegistry.release_cells(
		placeable.get_occupied_cells(),
		placeable
	)


func _set_physics_carried_state(value: bool) -> void:
	var physical_body := get_physical_body()

	if physical_body != null:
		physical_body.set_carried_state(value)

		if value:
			physical_body.set_body_collision_enabled(
				not disable_body_collision_while_carried
			)
		else:
			if enable_body_collision_when_dropped:
				physical_body.set_body_collision_enabled(true)
			elif enable_body_collision_when_placed:
				physical_body.set_body_collision_enabled(true)

		return

	var rigid_body := root_node as RigidBody2D

	if rigid_body != null:
		rigid_body.freeze = value

		if value:
			rigid_body.linear_velocity = Vector2.ZERO
			rigid_body.angular_velocity = 0.0


func _reset_rotation_for_carry() -> void:
	if root_node == null:
		return

	root_node.rotation = 0.0


func _apply_carrier_collision_exception(
	physical_body: PhysicalItemBody,
	new_carrier: Node2D
) -> void:
	if not ignore_carrier_collision_while_carried:
		return

	if physical_body == null:
		return

	var carrier_body := new_carrier as PhysicsBody2D

	if carrier_body == null:
		return

	_ignored_carrier_body = carrier_body
	physical_body.add_collision_exception_with(carrier_body)


func _clear_carrier_collision_exception(
	physical_body: PhysicalItemBody
) -> void:
	if physical_body == null:
		_ignored_carrier_body = null
		return

	if _ignored_carrier_body != null and is_instance_valid(_ignored_carrier_body):
		physical_body.remove_collision_exception_with(_ignored_carrier_body)

	_ignored_carrier_body = null


func _find_physical_body_recursive(node: Node) -> PhysicalItemBody:
	if node == null:
		return null

	if node is PhysicalItemBody:
		return node as PhysicalItemBody

	for child in node.get_children():
		var found := _find_physical_body_recursive(child)

		if found != null:
			return found

	return null


func _find_first_canvas_item(node: Node) -> CanvasItem:
	if node == null:
		return null

	if node is CanvasItem:
		return node as CanvasItem

	for child in node.get_children():
		var found := _find_first_canvas_item(child)

		if found != null:
			return found

	return null


func _notify_external_motion_begin_carried() -> void:
	if external_motion_component == null:
		return

	if external_motion_component.has_method("begin_carried"):
		external_motion_component.begin_carried()


func _notify_external_motion_end_carried() -> void:
	if external_motion_component == null:
		return

	if external_motion_component.has_method("end_carried"):
		external_motion_component.end_carried()


func _notify_external_motion_start_throw(
	throw_velocity: Vector2
) -> void:
	if external_motion_component == null:
		return

	if external_motion_component.has_method("start_external_motion"):
		external_motion_component.start_external_motion(
			throw_velocity
		)
