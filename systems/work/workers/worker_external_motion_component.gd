extends Node
class_name WorkerExternalMotionComponent

signal external_motion_started(initial_velocity: Vector2)
signal external_motion_landed(impact_speed: float)

@export var worker_body: CharacterBody2D

@export_group("Motion")
@export_range(0.0, 5.0, 0.01) var gravity_scale: float = 1.0
@export_range(0.0, 2.0, 0.01) var minimum_air_time: float = 0.18
@export_range(0.0, 500.0, 1.0) var leave_ground_speed_threshold: float = 20.0

@export_group("Control Lock")
@export var nodes_to_disable_while_external_motion: Array[Node] = []

var is_external_motion_active: bool = false
var is_carried: bool = false

var _velocity: Vector2 = Vector2.ZERO
var _elapsed_time: float = 0.0
var _max_fall_speed: float = 0.0
var _has_left_ground: bool = false

var _previous_process_states: Dictionary = {}
var _previous_physics_process_states: Dictionary = {}


func _ready() -> void:
	if worker_body == null:
		worker_body = owner as CharacterBody2D

	set_physics_process(false)


func begin_carried() -> void:
	is_carried = true
	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_max_fall_speed = 0.0
	_has_left_ground = false

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
	_max_fall_speed = maxf(initial_velocity.y, 0.0)
	_has_left_ground = false

	_disable_control_nodes()

	worker_body.velocity = _velocity
	set_physics_process(true)

	external_motion_started.emit(initial_velocity)


func cancel_external_motion() -> void:
	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_max_fall_speed = 0.0
	_has_left_ground = false

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO

	set_physics_process(false)

	if not is_carried:
		_enable_control_nodes()


func get_prediction_gravity() -> Vector2:
	if worker_body != null:
		return worker_body.get_gravity() * gravity_scale

	var gravity_value := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var gravity_vector := ProjectSettings.get_setting("physics/2d/default_gravity_vector") as Vector2

	return gravity_vector.normalized() * gravity_value * gravity_scale


func _physics_process(delta: float) -> void:
	if not is_external_motion_active:
		return

	if worker_body == null:
		cancel_external_motion()
		return

	_elapsed_time += delta

	_velocity += get_prediction_gravity() * delta

	worker_body.velocity = _velocity
	worker_body.move_and_slide()

	_velocity = worker_body.velocity

	if not worker_body.is_on_floor():
		_has_left_ground = true

	if absf(_velocity.y) > leave_ground_speed_threshold:
		_has_left_ground = true

	_max_fall_speed = maxf(_max_fall_speed, maxf(_velocity.y, 0.0))

	if _should_finish_external_motion():
		_finish_external_motion()


func _should_finish_external_motion() -> bool:
	if worker_body == null:
		return true

	if _elapsed_time < minimum_air_time:
		return false

	if not _has_left_ground:
		return false

	if _velocity.y < 0.0:
		return false

	return worker_body.is_on_floor()


func _finish_external_motion() -> void:
	var impact_speed := _max_fall_speed

	is_external_motion_active = false

	_velocity = Vector2.ZERO
	_elapsed_time = 0.0
	_max_fall_speed = 0.0
	_has_left_ground = false

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO

	set_physics_process(false)

	if not is_carried:
		_enable_control_nodes()

	external_motion_landed.emit(impact_speed)


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
