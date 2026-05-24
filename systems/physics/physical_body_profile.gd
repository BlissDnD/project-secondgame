extends Resource
class_name PhysicalBodyProfile

@export_range(0.01, 10000.0, 0.01) var weight: float = 1.0
@export_range(0.0, 5.0, 0.01) var gravity_scale: float = 2.0

@export_range(0.0, 20.0, 0.01) var linear_damping: float = 0.3
@export_range(0.0, 20.0, 0.01) var angular_damping: float = 0.8

@export_range(0.0, 1.0, 0.01) var bounce: float = 0.1
@export_range(0.0, 2.0, 0.01) var friction: float = 0.8

@export var rolls_when_moving: bool = false
@export var slides_when_moving: bool = true

@export_group("Carry")
@export var reset_rotation_on_pickup: bool = true
@export var carried_rotation: float = 0.0

@export_group("Release Safety")
@export_range(0.0, 1.0, 0.01) var thrower_collision_grace_time: float = 0.15

@export_group("High Speed Collision")
@export var use_continuous_collision_detection: bool = true
@export var use_shape_cast_ccd: bool = true
@export_range(0.0, 5000.0, 1.0) var max_throw_speed: float = 2200.0

@export_group("Heavy Impact")
@export var sticks_on_heavy_impact: bool = false
@export_range(0.0, 10000.0, 0.01) var heavy_impact_speed_threshold: float = 650.0
@export_range(0.0, 1.0, 0.01) var heavy_impact_velocity_keep_ratio: float = 0.15
