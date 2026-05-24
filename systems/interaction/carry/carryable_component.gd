extends Area2D
class_name CarryableComponent

signal picked_up(carrier: Node2D)
signal dropped(carrier: Node2D)
signal thrown(carrier: Node2D, velocity: Vector2)

@export var root_node: Node2D
@export var hold_offset: Vector2 = Vector2(0, -48)

@export var carry_profile: CarryProfile

@export var supports_grid_placement: bool = false
@export var placeable_definition: PlaceableDefinition
@export var footprint_tiles: Vector2i = Vector2i.ONE

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


func can_insert_into_worker_socket() -> bool:
	if carry_profile == null:
		return false

	return carry_profile.can_insert_into_worker_socket


func get_weight() -> float:
	if carry_profile == null:
		return 0.0

	return carry_profile.get_weight(root_node)


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
	_drop_internal(drop_position, inherited_velocity, true)


func throw_with_velocity(
	throw_position: Vector2,
	throw_velocity: Vector2,
	ignored_body: PhysicsBody2D = null
) -> void:
	if not can_be_thrown():
		return

	var old_carrier := carrier

	_drop_internal(throw_position, Vector2.ZERO, false)

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		_apply_thrower_collision_grace(physical_body, ignored_body)
		physical_body.linear_velocity = throw_velocity
		physical_body.angular_velocity = 0.0
		thrown.emit(old_carrier, throw_velocity)
		return

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		if ignored_body != null:
			rigid_body.add_collision_exception_with(ignored_body)

			var timer := get_tree().create_timer(0.15)
			timer.timeout.connect(
				func() -> void:
					if is_instance_valid(rigid_body) and is_instance_valid(ignored_body):
						rigid_body.remove_collision_exception_with(ignored_body)
			)

		rigid_body.linear_velocity = throw_velocity
		rigid_body.angular_velocity = 0.0
		thrown.emit(old_carrier, throw_velocity)
		return

	var external_motion := _find_external_motion_component()
	if external_motion != null:
		external_motion.start_external_motion(throw_velocity)

	thrown.emit(old_carrier, throw_velocity)


func throw_from(
	throw_position: Vector2,
	direction: Vector2,
	base_impulse: float,
	throw_strength: float,
	inherited_velocity: Vector2 = Vector2.ZERO,
	ignored_body: PhysicsBody2D = null
) -> void:
	if not can_be_thrown():
		return

	var weight := maxf(get_weight(), 0.01)
	var multiplier := get_throw_multiplier(throw_strength)
	var throw_velocity := direction.normalized() * base_impulse * multiplier / weight
	throw_velocity += inherited_velocity

	throw_with_velocity(throw_position, throw_velocity, ignored_body)


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
	end_external_carried_state: bool
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

	if root_node.has_method("on_dropped"):
		root_node.on_dropped()

	dropped.emit(old_carrier)


func _set_physics_carried_state(value: bool) -> void:
	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		physical_body.set_carried_state(value)

		if disable_body_collision_while_carried:
			physical_body.set_body_collision_enabled(not value)

		if not value and enable_body_collision_when_dropped:
			physical_body.set_body_collision_enabled(true)

		return

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.freeze = value

		if value:
			rigid_body.linear_velocity = Vector2.ZERO
			rigid_body.angular_velocity = 0.0


func _reset_rotation_for_carry() -> void:
	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		if physical_body.profile == null or physical_body.profile.reset_rotation_on_pickup:
			root_node.rotation = physical_body.profile.carried_rotation if physical_body.profile != null else 0.0
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
