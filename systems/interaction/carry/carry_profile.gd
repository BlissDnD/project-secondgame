extends Resource
class_name CarryProfile

@export var can_be_carried: bool = true
@export var can_be_thrown: bool = true
@export var can_drop_freely: bool = true
@export var can_insert_into_worker_socket: bool = false

@export_range(0.01, 10000.0, 0.01) var comfortable_weight_limit: float = 8.0
@export_range(0.0, 1.0, 0.01) var throw_efficiency: float = 1.0
