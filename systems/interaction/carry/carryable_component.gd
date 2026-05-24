extends Area2D
class_name CarryableComponent

signal picked_up(carrier: Node2D)
signal dropped(carrier: Node2D)
signal thrown(carrier: Node2D, impulse: Vector2)

@export var root_node: Node2D
@export var hold_offset: Vector2 = Vector2(24, -16)

@export var can_be_carried: bool = true
@export var can_be_thrown: bool = true
@export var can_drop_freely: bool = true
@export var requires_ground: bool = false

@export var supports_grid_placement: bool = false
@export var can_insert_into_worker_socket: bool = false

@export var placeable_definition: PlaceableDefinition
@export var footprint_tiles: Vector2i = Vector2i.ONE

@export_range(0.01, 10000.0, 0.01) var pickup_weight_limit: float = 25.0
@export_range(0.01, 10000.0, 0.01) var comfortable_weight_limit: float = 8.0
@export_range(0.0, 1.0, 0.01) var throw_efficiency: float = 1.0

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


func _ready() -> void:
	if root_node == null:
		root_node = owner as Node2D

	if highlight_target == null:
		highlight_target = _find_first_canvas_item(root_node)

	if highlight_target != null:
		_default_modulate = highlight_target.modulate


func can_carry() -> bool:
	return can_be_carried and root_node != null


func can_be_lifted_by(lift_strength: float) -> bool:
	if not can_carry():
		return false

	var weight := get_weight()
	return weight <= lift_strength and weight <= pickup_weight_limit


func get_weight() -> float:
	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		return physical_body.get_weight()

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		return rigid_body.mass

	return 0.0


func get_carry_speed_multiplier(carry_strength: float) -> float:
	var weight := get_weight()

	if weight <= comfortable_weight_limit:
		return 1.0

	var overload := weight - comfortable_weight_limit
	var penalty := overload / maxf(carry_strength, 0.01)

	return clampf(1.0 - penalty, 0.25, 1.0)


func get_throw_multiplier(throw_strength: float) -> float:
	if not can_be_thrown:
		return 0.0

	var weight := get_weight()
	var strength_base := maxf(throw_strength, 0.01)
	var mass_factor := strength_base / (strength_base + weight)

	return clampf(mass_factor * throw_efficiency, 0.0, 1.0)


func get_carried_root() -> Node2D:
	return root_node


func pickup(new_carrier: Node2D) -> bool:
	if not can_carry():
		return false

	original_parent = root_node.get_parent()
	carrier = new_carrier
	is_carried = true

	set_highlighted(false)
	_set_physics_carried_state(true)

	if root_node.has_method("on_picked_up"):
		root_node.on_picked_up()

	picked_up.emit(carrier)
	return true


func drop(drop_position: Vector2, inherited_velocity: Vector2 = Vector2.ZERO) -> void:
	if root_node == null:
		return

	root_node.global_position = drop_position

	var old_carrier := carrier
	carrier = null
	is_carried = false

	_set_physics_carried_state(false)

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		physical_body.linear_velocity = inherited_velocity

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.linear_velocity = inherited_velocity

	if root_node.has_method("on_dropped"):
		root_node.on_dropped()

	dropped.emit(old_carrier)


func throw_from(
	throw_position: Vector2,
	direction: Vector2,
	base_impulse: float,
	throw_strength: float,
	inherited_velocity: Vector2 = Vector2.ZERO
) -> void:
	var old_carrier := carrier
	var multiplier := get_throw_multiplier(throw_strength)

	drop(throw_position, inherited_velocity)

	if direction.length() <= 0.0:
		return

	var impulse := direction.normalized() * base_impulse * multiplier

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		physical_body.apply_external_impulse(impulse)
		thrown.emit(old_carrier, impulse)
		return

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		rigid_body.apply_central_impulse(impulse)
		thrown.emit(old_carrier, impulse)


func carry_update() -> void:
	if not is_carried:
		return

	if carrier == null:
		return

	if root_node == null:
		return

	root_node.global_position = carrier.global_position + hold_offset


func set_highlighted(value: bool) -> void:
	if _is_highlighted == value:
		return

	_is_highlighted = value

	if highlight_target == null:
		return

	if value:
		highlight_target.modulate = highlight_color
	else:
		highlight_target.modulate = _default_modulate


func is_highlighted() -> bool:
	return _is_highlighted


func on_picked_up(_by_actor: Node2D) -> void:
	pass


func on_dropped(_by_actor: Node2D) -> void:
	pass


func on_placed(_by_actor: Node2D) -> void:
	pass


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
