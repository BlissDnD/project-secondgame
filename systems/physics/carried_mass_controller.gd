extends Node
class_name CarriedMassController

signal carried_body_changed(body: PhysicalItemBody)
signal carried_body_cleared()

@export_range(0.01, 10000.0, 0.01) var base_player_weight: float = 70.0
@export_range(0.01, 10000.0, 0.01) var lift_strength: float = 25.0
@export_range(0.01, 10000.0, 0.01) var comfort_strength: float = 30.0
@export_range(0.01, 10000.0, 0.01) var throw_strength: float = 20.0
@export_range(0.01, 10000.0, 0.01) var base_throw_impulse: float = 650.0

var carried_body: PhysicalItemBody = null

func has_carried_body() -> bool:
	return carried_body != null


func try_pickup(body: PhysicalItemBody, carrier: Node2D) -> bool:
	if body == null:
		return false

	if carried_body != null:
		return false

	if not body.can_be_picked_up_by(lift_strength):
		return false

	carried_body = body
	carried_body.pickup(carrier)

	carried_body_changed.emit(carried_body)
	return true


func drop_at(world_position: Vector2, inherited_velocity: Vector2 = Vector2.ZERO) -> void:
	if carried_body == null:
		return

	var body_to_drop: PhysicalItemBody = carried_body
	carried_body = null

	body_to_drop.drop(world_position, inherited_velocity)
	carried_body_cleared.emit()


func throw_at(world_position: Vector2, direction: Vector2, inherited_velocity: Vector2 = Vector2.ZERO) -> void:
	if carried_body == null:
		return

	var body_to_throw: PhysicalItemBody = carried_body
	carried_body = null

	body_to_throw.throw_from(
		world_position,
		direction,
		base_throw_impulse,
		throw_strength,
		inherited_velocity
	)

	carried_body_cleared.emit()


func get_carried_weight() -> float:
	if carried_body == null:
		return 0.0

	return carried_body.get_weight()


func get_effective_player_weight() -> float:
	return base_player_weight + get_carried_weight()


func get_movement_speed_multiplier() -> float:
	if carried_body == null:
		return 1.0

	if carried_body.profile == null:
		return 1.0

	return carried_body.profile.get_carry_speed_multiplier(comfort_strength)
