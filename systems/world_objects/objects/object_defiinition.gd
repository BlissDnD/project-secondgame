extends Resource
class_name ObjectDefinition

@export var id: StringName
@export var display_name: String

@export var physics_profile: ItemPhysicsProfile

@export var can_be_carried: bool = false
@export var can_be_placed: bool = false
@export var can_be_stored_in_inventory: bool = false
@export var can_insert_into_worker_socket: bool = false
