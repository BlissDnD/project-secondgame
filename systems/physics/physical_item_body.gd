extends RigidBody2D
class_name PhysicalItemBody

signal heavy_impact(body: PhysicalItemBody, impact_speed: float)

@export var profile: PhysicalBodyProfile

var _default_collision_layer: int = 0
var _default_collision_mask: int = 0


func _ready() -> void:
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	apply_profile()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
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


func get_weight() -> float:
	if profile != null:
		return profile.weight

	return mass


func set_carried_state(enabled: bool) -> void:
	if enabled:
		freeze = true
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
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


func _handle_heavy_impact(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0:
		return

	var speed := state.linear_velocity.length()

	if speed < profile.heavy_impact_speed_threshold:
		return

	state.linear_velocity *= profile.heavy_impact_velocity_keep_ratio
	state.angular_velocity *= profile.heavy_impact_velocity_keep_ratio

	heavy_impact.emit(self, speed)
