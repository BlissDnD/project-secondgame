@tool
extends RigidBody2D
class_name PhysicalItemBody

signal heavy_impact(body: PhysicalItemBody, impact_speed: float)

@export var profile: PhysicalBodyProfile:
	set(value):
		profile = value
		_connect_profile_changed()
		apply_profile()

var _default_collision_layer: int = 0
var _default_collision_mask: int = 0
var _last_profile_signature: String = ""


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

	if profile == null:
		return

	if profile.sticks_on_heavy_impact:
		_handle_heavy_impact(state)


func apply_profile() -> void:
	if profile == null:
		return

	mass = maxf(profile.weight, 0.01)
	gravity_scale = profile.gravity_scale
	linear_damp = profile.linear_damping
	angular_damp = profile.angular_damping

	var material := PhysicsMaterial.new()
	material.bounce = profile.bounce
	material.friction = profile.friction
	physics_material_override = material

	lock_rotation = profile.slides_when_moving and not profile.rolls_when_moving
	_apply_continuous_collision_detection()

	_last_profile_signature = _get_profile_signature()


func get_weight() -> float:
	if profile != null:
		return profile.weight

	return mass


func get_thrower_collision_grace_time() -> float:
	if profile == null:
		return 0.15

	return profile.thrower_collision_grace_time


func get_max_throw_speed() -> float:
	if profile == null:
		return 2200.0

	return profile.max_throw_speed


func set_carried_state(enabled: bool) -> void:
	if enabled:
		freeze = true
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

		if profile == null or profile.reset_rotation_on_pickup:
			rotation = profile.carried_rotation if profile != null else 0.0
	else:
		freeze = false
		apply_profile()


func set_body_collision_enabled(enabled: bool) -> void:
	if enabled:
		collision_layer = _default_collision_layer
		collision_mask = _default_collision_mask
	else:
		collision_layer = 0
		collision_mask = 0


func apply_external_impulse(impulse: Vector2) -> void:
	if freeze:
		return

	apply_central_impulse(impulse)


func apply_external_force(force: Vector2) -> void:
	if freeze:
		return

	apply_central_force(force)


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


func _apply_continuous_collision_detection() -> void:
	if profile == null:
		return

	if not profile.use_continuous_collision_detection:
		continuous_cd = RigidBody2D.CCD_MODE_DISABLED
		return

	if profile.use_shape_cast_ccd:
		continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	else:
		continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY


func _connect_profile_changed() -> void:
	if profile == null:
		return

	if not profile.changed.is_connected(_on_profile_changed):
		profile.changed.connect(_on_profile_changed)


func _on_profile_changed() -> void:
	apply_profile()


func _get_profile_signature() -> String:
	if profile == null:
		return ""

	return str([
		profile.weight,
		profile.gravity_scale,
		profile.linear_damping,
		profile.angular_damping,
		profile.bounce,
		profile.friction,
		profile.rolls_when_moving,
		profile.slides_when_moving,
		profile.reset_rotation_on_pickup,
		profile.carried_rotation,
		profile.thrower_collision_grace_time,
		profile.use_continuous_collision_detection,
		profile.use_shape_cast_ccd,
		profile.max_throw_speed,
		profile.sticks_on_heavy_impact,
		profile.heavy_impact_speed_threshold,
		profile.heavy_impact_velocity_keep_ratio
	])


func _handle_heavy_impact(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0:
		return

	var speed := state.linear_velocity.length()

	if speed < profile.heavy_impact_speed_threshold:
		return

	state.linear_velocity *= profile.heavy_impact_velocity_keep_ratio
	state.angular_velocity *= profile.heavy_impact_velocity_keep_ratio

	heavy_impact.emit(self, speed)
