extends Node
class_name WorkerExternalMotionComponent

signal external_motion_started(initial_velocity: Vector2)
signal external_motion_landed(impact_speed: float)
signal external_motion_finished(impact_speed: float)

@export var worker_body: CharacterBody2D
@export var motion_profile: PhysicalMotionProfile

@export_group("Visual Roll")
@export var visual_roll_target: Node2D
@export_range(0.0, 20.0, 0.01) var visual_roll_speed_multiplier: float = 0.025

@export_group("Landing / Settle")
@export_range(0.0, 2.0, 0.01) var minimum_air_time: float = 0.18
@export_range(0.0, 500.0, 1.0) var leave_ground_speed_threshold: float = 20.0
@export_range(0.0, 500.0, 1.0) var finish_speed_threshold: float = 35.0
@export_range(0.0, 2.0, 0.01) var minimum_settle_time: float = 0.12
@export_range(0.0, 5000.0, 1.0) var bounce_min_impact_speed: float = 120.0

@export_group("Control Lock")
@export var nodes_to_disable_while_external_motion: Array[Node] = []

@export_group("Lifecycle")
@export var call_owner_on_external_motion_finished: bool = true
@export var fallback_to_on_dropped_when_finished: bool = true

var is_external_motion_active: bool = false
var is_carried: bool = false

var _velocity: Vector2 = Vector2.ZERO
var _elapsed_time: float = 0.0
var _settle_time: float = 0.0
var _max_fall_speed: float = 0.0
var _last_impact_speed: float = 0.0
var _has_left_ground: bool = false
var _has_landed: bool = false

var _previous_process_states: Dictionary = {}
var _previous_physics_process_states: Dictionary = {}


func _ready() -> void:
	if worker_body == null:
		worker_body = owner as CharacterBody2D

	if visual_roll_target == null:
		visual_roll_target = _find_first_visual_node(owner)

	set_physics_process(false)


func begin_carried() -> void:
	is_carried = true
	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_settle_time = 0.0
	_max_fall_speed = 0.0
	_last_impact_speed = 0.0
	_has_left_ground = false
	_has_landed = false

	_disable_control_nodes()
	set_physics_process(false)

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO


func end_carried() -> void:
	is_carried = false

	if not is_external_motion_active:
		_enable_control_nodes()


func start_external_motion(initial_velocity: Vector2) -> void:
	if worker_body == null:
		return

	is_carried = false
	is_external_motion_active = true

	_velocity = initial_velocity
	_elapsed_time = 0.0
	_settle_time = 0.0
	_max_fall_speed = maxf(initial_velocity.y, 0.0)
	_last_impact_speed = 0.0
	_has_left_ground = false
	_has_landed = false

	_disable_control_nodes()

	worker_body.velocity = _velocity
	set_physics_process(true)

	external_motion_started.emit(initial_velocity)


func cancel_external_motion() -> void:
	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_settle_time = 0.0
	_max_fall_speed = 0.0
	_last_impact_speed = 0.0
	_has_left_ground = false
	_has_landed = false

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO

	set_physics_process(false)

	if not is_carried:
		_enable_control_nodes()


func get_motion_profile() -> PhysicalMotionProfile:
	return motion_profile


func get_prediction_gravity() -> Vector2:
	if motion_profile != null:
		return motion_profile.get_gravity()

	if worker_body != null:
		return worker_body.get_gravity()

	var gravity_value := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var gravity_vector := ProjectSettings.get_setting("physics/2d/default_gravity_vector") as Vector2

	return gravity_vector.normalized() * gravity_value


func _physics_process(delta: float) -> void:
	if not is_external_motion_active:
		return

	if worker_body == null:
		cancel_external_motion()
		return

	_elapsed_time += delta

	if not _has_landed:
		_apply_air_motion(delta)
	else:
		_apply_ground_settle_motion(delta)

	worker_body.velocity = _velocity
	worker_body.move_and_slide()
	_velocity = worker_body.velocity

	_process_collisions_after_move()
	_update_visual_roll(delta)

	if not worker_body.is_on_floor():
		_has_left_ground = true

	if absf(_velocity.y) > leave_ground_speed_threshold:
		_has_left_ground = true

	_max_fall_speed = maxf(_max_fall_speed, maxf(_velocity.y, 0.0))

	if _should_mark_landed():
		_mark_landed()

	if _has_landed:
		_settle_time += delta

		if _should_finish_external_motion():
			_finish_external_motion()


func _apply_air_motion(delta: float) -> void:
	_velocity += get_prediction_gravity() * delta

	if motion_profile != null:
		_velocity = motion_profile.apply_linear_damping(_velocity, delta)


func _apply_ground_settle_motion(delta: float) -> void:
	if motion_profile == null:
		_velocity.x = move_toward(_velocity.x, 0.0, 600.0 * delta)
		_velocity.y += get_prediction_gravity().y * delta
		return

	var friction_deceleration := motion_profile.friction * 1800.0
	var damping_deceleration := motion_profile.linear_damping * 120.0
	var total_deceleration := friction_deceleration + damping_deceleration

	if not motion_profile.slides_when_moving:
		total_deceleration *= 3.0

	_velocity.x = move_toward(_velocity.x, 0.0, total_deceleration * delta)
	_velocity.y += get_prediction_gravity().y * delta


func _process_collisions_after_move() -> void:
	if motion_profile == null:
		return

	if worker_body.get_slide_collision_count() <= 0:
		return

	for i in range(worker_body.get_slide_collision_count()):
		var collision := worker_body.get_slide_collision(i)
		if collision == null:
			continue

		var normal := collision.get_normal()
		var impact_speed := _velocity.length()

		if normal.y < -0.6:
			_handle_floor_collision(impact_speed, normal)
			continue

		_handle_wall_or_ceiling_collision(impact_speed, normal)


func _handle_floor_collision(impact_speed: float, normal: Vector2) -> void:
	if motion_profile == null:
		return

	if motion_profile.bounce > 0.0 and impact_speed >= bounce_min_impact_speed:
		_velocity = _velocity.bounce(normal) * motion_profile.bounce

		if absf(_velocity.y) > leave_ground_speed_threshold:
			_has_landed = false
			_settle_time = 0.0
			return

	if motion_profile.slides_when_moving:
		_velocity.y = 0.0
	else:
		_velocity = Vector2.ZERO


func _handle_wall_or_ceiling_collision(impact_speed: float, normal: Vector2) -> void:
	if motion_profile == null:
		return

	if motion_profile.bounce > 0.0 and impact_speed >= bounce_min_impact_speed:
		_velocity = _velocity.bounce(normal) * motion_profile.bounce
	else:
		_velocity = _velocity.slide(normal)


func _should_mark_landed() -> bool:
	if _has_landed:
		return false

	if _elapsed_time < minimum_air_time:
		return false

	if not _has_left_ground:
		return false

	if _velocity.y < 0.0:
		return false

	return worker_body.is_on_floor()


func _mark_landed() -> void:
	_has_landed = true
	_settle_time = 0.0
	_last_impact_speed = _max_fall_speed

	external_motion_landed.emit(_last_impact_speed)


func _should_finish_external_motion() -> bool:
	if not _has_landed:
		return false

	if _settle_time < minimum_settle_time:
		return false

	if not worker_body.is_on_floor():
		return false

	if absf(_velocity.x) > finish_speed_threshold:
		return false

	if absf(_velocity.y) > finish_speed_threshold:
		return false

	return true


func _finish_external_motion() -> void:
	var impact_speed := _last_impact_speed

	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_settle_time = 0.0
	_max_fall_speed = 0.0
	_last_impact_speed = 0.0
	_has_left_ground = false
	_has_landed = false

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO

	set_physics_process(false)

	if not is_carried:
		_enable_control_nodes()

	_notify_owner_external_motion_finished(impact_speed)
	external_motion_finished.emit(impact_speed)


func _update_visual_roll(delta: float) -> void:
	if motion_profile == null:
		return

	if not motion_profile.rolls_when_moving:
		return

	if visual_roll_target == null:
		return

	var horizontal_speed := _velocity.x

	if absf(horizontal_speed) <= 1.0:
		return

	visual_roll_target.rotation += horizontal_speed * visual_roll_speed_multiplier * delta


func _notify_owner_external_motion_finished(impact_speed: float) -> void:
	if not call_owner_on_external_motion_finished:
		return

	var target := owner

	if target == null:
		return

	if target.has_method("on_external_motion_finished"):
		target.on_external_motion_finished(impact_speed)
		return

	if fallback_to_on_dropped_when_finished and target.has_method("on_dropped"):
		target.on_dropped()


func _disable_control_nodes() -> void:
	for node in nodes_to_disable_while_external_motion:
		if node == null:
			continue

		if node == self:
			continue

		if not _previous_process_states.has(node):
			_previous_process_states[node] = node.is_processing()

		if not _previous_physics_process_states.has(node):
			_previous_physics_process_states[node] = node.is_physics_processing()

		node.set_process(false)
		node.set_physics_process(false)


func _enable_control_nodes() -> void:
	for node in nodes_to_disable_while_external_motion:
		if node == null:
			continue

		if _previous_process_states.has(node):
			node.set_process(bool(_previous_process_states[node]))

		if _previous_physics_process_states.has(node):
			node.set_physics_process(bool(_previous_physics_process_states[node]))

	_previous_process_states.clear()
	_previous_physics_process_states.clear()


func _find_first_visual_node(node: Node) -> Node2D:
	if node == null:
		return null

	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child as Node2D

	for child in node.get_children():
		if child is Sprite2D:
			return child as Node2D

	for child in node.get_children():
		var found := _find_first_visual_node(child)

		if found != null:
			return found

	return null
