extends Resource
class_name PhysicalMotionProfile

@export_group("Core")
@export_range(0.01, 10000.0, 0.01) var weight: float = 1.0
@export_range(0.0, 10.0, 0.01) var gravity_scale: float = 1.0
@export_range(0.0, 100.0, 0.01) var linear_damping: float = 0.0
@export_range(0.0, 100.0, 0.01) var angular_damping: float = 0.0
@export_range(0.0, 1.0, 0.01) var bounce: float = 0.0
@export_range(0.0, 1.0, 0.01) var friction: float = 1.0

@export_group("Movement")
@export var rolls_when_moving: bool = false
@export var slides_when_moving: bool = true

@export_group("Carry")
@export var reset_rotation_on_pickup: bool = true
@export var carried_rotation: float = 0.0

@export_group("Release Safety")
@export_range(0.0, 1.0, 0.01) var thrower_collision_grace_time: float = 0.05

@export_group("Throw")
@export_range(0.0, 10000.0, 1.0) var max_throw_speed: float = 2200.0

@export_group("CCD")
@export var use_continuous_collision_detection: bool = true
@export var use_shape_cast_ccd: bool = true

@export_group("Heavy Impact")
@export var sticks_on_heavy_impact: bool = false
@export_range(0.0, 10000.0, 1.0) var heavy_impact_speed_threshold: float = 650.0
@export_range(0.0, 1.0, 0.01) var heavy_impact_velocity_keep_ratio: float = 0.15


func get_gravity() -> Vector2:
	var gravity_value := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var gravity_vector := ProjectSettings.get_setting("physics/2d/default_gravity_vector") as Vector2
	return gravity_vector.normalized() * gravity_value * gravity_scale


func apply_linear_damping(velocity: Vector2, delta: float) -> Vector2:
	var damping := clampf(linear_damping * delta, 0.0, 1.0)
	return velocity.lerp(Vector2.ZERO, damping)
