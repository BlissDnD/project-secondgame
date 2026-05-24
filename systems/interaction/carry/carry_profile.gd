extends Resource
class_name CarryProfile

enum WeightSource {
	PHYSICAL_BODY,
	PROFILE_VALUE
}

@export var weight_source: WeightSource = WeightSource.PHYSICAL_BODY
@export_range(0.01, 10000.0, 0.01) var carried_weight: float = 1.0

@export var can_be_carried: bool = true
@export var can_be_thrown: bool = true
@export var can_drop_freely: bool = true
@export var can_insert_into_worker_socket: bool = false

@export_range(0.01, 10000.0, 0.01) var comfortable_weight_limit: float = 8.0
@export_range(0.0, 1.0, 0.01) var throw_efficiency: float = 1.0


func get_weight(root_node: Node2D) -> float:
	if weight_source == WeightSource.PROFILE_VALUE:
		return carried_weight

	var physical_body := root_node as PhysicalItemBody
	if physical_body != null:
		return physical_body.get_weight()

	var rigid_body := root_node as RigidBody2D
	if rigid_body != null:
		return rigid_body.mass

	return carried_weight
