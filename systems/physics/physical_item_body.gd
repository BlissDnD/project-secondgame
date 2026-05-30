@tool
extends RigidBody2D
class_name PhysicalItemBody

signal heavy_impact(body: PhysicalItemBody, impact_speed: float)

@export var motion_profile: PhysicalMotionProfile:
	set(value):
		motion_profile = value
		_connect_profile_changed()
		apply_profile()

@export_group("Physical Carry")
@export var physical_carry_max_speed: float = 1800.0

var _default_collision_layer: int = 0
var _default_collision_mask: int = 0
var _last_profile_signature: String = ""

var _physical_carry_target: Node2D = null
var _physical_carry_offset: Vector2 = Vector2.ZERO
var _physical_carry_strength: float = 45.0
var _physical_carry_damping: float = 10.0
var _is_physically_carried: bool = false


func _ready() -> void:
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	_connect_profile_changed()
	apply_profile()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	if _get_profile_signature() != _last_profile_signature:
		apply_profile()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if Engine.is_editor_hint():
		return

	if _is_physically_carried:
		_integrate_physical_carry(state)
		return

	if motion_profile == null:
		return

	if motion_profile.sticks_on_heavy_impact:
		_handle_heavy_impact(state)


func apply_profile() -> void:
	if motion_profile == null:
		return

	mass = maxf(motion_profile.weight, 0.01)
	gravity_scale = motion_profile.gravity_scale
	linear_damp = motion_profile.linear_damping
	angular_damp = motion_profile.angular_damping

	var material := PhysicsMaterial.new()
	material.bounce = motion_profile.bounce
	material.friction = motion_profile.friction
	physics_material_override = material

	lock_rotation = motion_profile.slides_when_moving and not motion_profile.rolls_when_moving
	_apply_continuous_collision_detection()

	_last_profile_signature = _get_profile_signature()


func get_motion_profile() -> PhysicalMotionProfile:
	return motion_profile


func get_weight() -> float:
	if motion_profile != null:
		return motion_profile.weight

	return mass


func get_thrower_collision_grace_time() -> float:
	if motion_profile == null:
		return 0.05

	return motion_profile.thrower_collision_grace_time


func get_max_throw_speed() -> float:
	if motion_profile == null:
		return physical_carry_max_speed

	return motion_profile.max_throw_speed


func set_carried_state(enabled: bool) -> void:
	if enabled:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

		if motion_profile == null or motion_profile.reset_rotation_on_pickup:
			rotation = motion_profile.carried_rotation if motion_profile != null else 0.0
	else:
		clear_physical_carry_target()
		freeze = false
		apply_profile()


func set_physical_carry_target(
	target: Node2D,
	offset: Vector2 = Vector2.ZERO,
	strength: float = 45.0,
	damping: float = 10.0
) -> void:
	_physical_carry_target = target
	_physical_carry_offset = offset
	_physical_carry_strength = strength
	_physical_carry_damping = damping
	_is_physically_carried = target != null

	if _is_physically_carried:
		freeze = false
		sleeping = false
		gravity_scale = 0.0
		linear_damp = 0.0
		angular_damp = 8.0
	else:
		apply_profile()


func clear_physical_carry_target() -> void:
	_physical_carry_target = null
	_physical_carry_offset = Vector2.ZERO
	_is_physically_carried = false
	apply_profile()


func is_physically_carried() -> bool:
	return _is_physically_carried


func set_body_collision_enabled(enabled: bool) -> void:
	if enabled:
		collision_layer = _default_collision_layer
		collision_mask = _default_collision_mask
	else:
		collision_layer = 0
		collision_mask = 0


func temporarily_ignore_body(body: PhysicsBody2D, duration: float) -> void:
	if body == null:
		return

	add_collision_exception_with(body)

	if duration <= 0.0:
		return

	var timer := get_tree().create_timer(duration)

	timer.timeout.connect(
		func() -> void:
			if is_instance_valid(self) and is_instance_valid(body):
				remove_collision_exception_with(body)
	)


func apply_external_impulse(impulse: Vector2) -> void:
	if freeze:
		return

	apply_central_impulse(impulse)


func apply_external_force(force: Vector2) -> void:
	if freeze:
		return

	apply_central_force(force)


func _integrate_physical_carry(state: PhysicsDirectBodyState2D) -> void:
	if _physical_carry_target == null or not is_instance_valid(_physical_carry_target):
		clear_physical_carry_target()
		return

	var target_position := _physical_carry_target.global_position + _physical_carry_offset
	var current_position := state.transform.origin
	var to_target := target_position - current_position

	var desired_velocity := to_target * _physical_carry_strength
	var alpha := clampf(_physical_carry_damping * state.step, 0.0, 1.0)

	var new_velocity := state.linear_velocity.lerp(desired_velocity, alpha)

	var max_speed := get_max_throw_speed()

	if max_speed <= 0.0:
		max_speed = physical_carry_max_speed

	if new_velocity.length() > max_speed:
		new_velocity = new_velocity.normalized() * max_speed

	state.linear_velocity = new_velocity
	state.angular_velocity = 0.0


func _apply_continuous_collision_detection() -> void:
	if motion_profile == null:
		return

	if not motion_profile.use_continuous_collision_detection:
		continuous_cd = RigidBody2D.CCD_MODE_DISABLED
		return

	if motion_profile.use_shape_cast_ccd:
		continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	else:
		continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY


func _connect_profile_changed() -> void:
	if motion_profile == null:
		return

	if not motion_profile.changed.is_connected(_on_profile_changed):
		motion_profile.changed.connect(_on_profile_changed)


func _on_profile_changed() -> void:
	apply_profile()


func _get_profile_signature() -> String:
	if motion_profile == null:
		return ""

	return str([
		motion_profile.weight,
		motion_profile.gravity_scale,
		motion_profile.linear_damping,
		motion_profile.angular_damping,
		motion_profile.bounce,
		motion_profile.friction,
		motion_profile.rolls_when_moving,
		motion_profile.slides_when_moving,
		motion_profile.reset_rotation_on_pickup,
		motion_profile.carried_rotation,
		motion_profile.thrower_collision_grace_time,
		motion_profile.max_throw_speed,
		motion_profile.use_continuous_collision_detection,
		motion_profile.use_shape_cast_ccd,
		motion_profile.sticks_on_heavy_impact,
		motion_profile.heavy_impact_speed_threshold,
		motion_profile.heavy_impact_velocity_keep_ratio
	])


func _handle_heavy_impact(state: PhysicsDirectBodyState2D) -> void:
	if motion_profile == null:
		return

	if state.get_contact_count() <= 0:
		return

	var speed := state.linear_velocity.length()

	if speed < motion_profile.heavy_impact_speed_threshold:
		return

	state.linear_velocity *= motion_profile.heavy_impact_velocity_keep_ratio
	state.angular_velocity = 0.0

	heavy_impact.emit(self, speed)
