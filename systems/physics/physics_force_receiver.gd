extends Node
class_name PhysicsForceReceiver

@export var physical_body: PhysicalItemBody
@export var can_receive_impulses: bool = true
@export var can_receive_forces: bool = true
@export_range(0.0, 10.0, 0.01) var force_response_multiplier: float = 1.0


func _ready() -> void:
	if physical_body == null:
		physical_body = get_parent() as PhysicalItemBody


func apply_impulse(impulse: Vector2) -> void:
	if not can_receive_impulses:
		return

	if physical_body == null:
		return

	physical_body.apply_external_impulse(impulse * force_response_multiplier)


func apply_force(force: Vector2) -> void:
	if not can_receive_forces:
		return

	if physical_body == null:
		return

	physical_body.apply_external_force(force * force_response_multiplier)
