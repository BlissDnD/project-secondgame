extends Node
class_name WorkerMovementComponent

signal reached_target
signal blocked

enum MovementMode {
	NONE,
	TARGET,
	WANDER
}

enum ObstacleResult {
	NONE,
	STEPPED,
	JUMPED,
	TURNED,
	BLOCKED
}

@export_category("References")
@export var worker_body: CharacterBody2D
@export var floor_ray: RayCast2D
@export var step_ray: RayCast2D
@export var step_height_ray: RayCast2D
@export var clearance_ray: RayCast2D
@export var gap_ray: RayCast2D

@export_category("Horizontal Movement")
@export var move_speed: float = 70.0
@export var wander_speed: float = 45.0
@export var gravity: float = 900.0
@export var target_reach_distance: float = 18.0

@export_category("Step Up")
@export var step_up_enabled: bool = true
@export var step_climb_vertical_velocity: float = -90.0
@export var step_climb_forward_multiplier: float = 2.0
@export var step_climb_duration: float = 0.16
@export var step_cooldown_time: float = 0.08
@export var minimum_ground_time_before_step: float = 0.0

@export_category("Jump")
@export var obstacle_jump_enabled: bool = true
@export var jump_velocity: float = -520.0
@export var jump_forward_speed_multiplier: float = 1.15
@export var jump_cooldown_time: float = 0.45
@export var minimum_ground_time_before_jump: float = 0.05
@export var max_jump_attempts_before_turn: int = 1

@export_category("Wander")
@export var wander_move_time_min: float = 1.0
@export var wander_move_time_max: float = 3.0
@export var wander_pause_time_min: float = 0.5
@export var wander_pause_time_max: float = 1.4
@export_range(0.0, 1.0, 0.01) var wander_turn_chance: float = 0.35
@export var wander_turn_on_gap: bool = false
@export var wander_turn_when_blocked: bool = true

@export_category("Debug")
@export var debug_obstacles: bool = false

var target_position: Vector2
var has_target: bool = false
var movement_mode: MovementMode = MovementMode.NONE

var wander_direction: int = 1
var wander_timer: float = 0.0
var wander_paused: bool = false

var ground_time: float = 0.0
var step_cooldown: float = 0.0
var jump_cooldown: float = 0.0
var jump_attempts: int = 0
var last_obstacle_direction: float = 0.0

var step_climb_timer: float = 0.0
var step_climb_direction: float = 0.0


func _ready() -> void:
	randomize()

	if worker_body == null:
		worker_body = get_parent() as CharacterBody2D

	_randomize_wander()


func set_target(position: Vector2) -> void:
	target_position = position
	has_target = true
	movement_mode = MovementMode.TARGET
	_reset_obstacle_memory()


func clear_target() -> void:
	has_target = false

	if movement_mode == MovementMode.TARGET:
		movement_mode = MovementMode.NONE

	if worker_body != null:
		worker_body.velocity.x = 0.0


func start_wander() -> void:
	has_target = false
	movement_mode = MovementMode.WANDER

	if wander_timer <= 0.0:
		_randomize_wander()


func stop_wander() -> void:
	if movement_mode == MovementMode.WANDER:
		movement_mode = MovementMode.NONE

	wander_paused = false

	if worker_body != null:
		worker_body.velocity.x = 0.0


func stop_all() -> void:
	has_target = false
	movement_mode = MovementMode.NONE
	wander_paused = false
	_stop_step_climb()
	_reset_obstacle_memory()

	if worker_body != null:
		worker_body.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	if worker_body == null:
		return

	_update_timers(delta)

	if step_climb_timer > 0.0:
		_update_step_climb(delta)
		return

	_apply_gravity(delta)

	match movement_mode:
		MovementMode.TARGET:
			_target_update(delta)

		MovementMode.WANDER:
			_wander_update(delta)

		MovementMode.NONE:
			worker_body.velocity.x = 0.0
			worker_body.move_and_slide()


func _update_timers(delta: float) -> void:
	if step_cooldown > 0.0:
		step_cooldown -= delta

	if jump_cooldown > 0.0:
		jump_cooldown -= delta

	if worker_body != null and worker_body.is_on_floor():
		ground_time += delta
	else:
		ground_time = 0.0


func _target_update(_delta: float) -> void:
	if not has_target:
		worker_body.velocity.x = 0.0
		movement_mode = MovementMode.NONE
		worker_body.move_and_slide()
		return

	var distance_to_target := worker_body.global_position.distance_to(target_position)
	if distance_to_target <= target_reach_distance:
		worker_body.velocity.x = 0.0
		has_target = false
		movement_mode = MovementMode.NONE
		worker_body.move_and_slide()
		reached_target.emit()
		return

	var direction := signf(target_position.x - worker_body.global_position.x)
	if direction == 0.0:
		direction = 1.0

	var result := _handle_forward_obstacle(direction, false)
	if result == ObstacleResult.STEPPED or result == ObstacleResult.JUMPED:
		worker_body.move_and_slide()
		return

	if result == ObstacleResult.BLOCKED:
		_stop_as_blocked()
		worker_body.move_and_slide()
		return

	worker_body.velocity.x = direction * move_speed
	worker_body.move_and_slide()


func _wander_update(delta: float) -> void:
	wander_timer -= delta

	if wander_paused:
		worker_body.velocity.x = 0.0

		if wander_timer <= 0.0:
			wander_paused = false
			wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
			_update_rays(float(wander_direction))

		worker_body.move_and_slide()
		return

	var direction := float(wander_direction)
	_update_rays(direction)

	if wander_turn_on_gap and _detect_gap():
		_turn_wander()
		worker_body.move_and_slide()
		return

	var result := _handle_forward_obstacle(direction, true)
	if result == ObstacleResult.STEPPED or result == ObstacleResult.JUMPED or result == ObstacleResult.TURNED:
		worker_body.move_and_slide()
		return

	if wander_timer <= 0.0:
		if randf() < wander_turn_chance:
			_turn_wander()
		else:
			wander_paused = true
			wander_timer = randf_range(wander_pause_time_min, wander_pause_time_max)

	worker_body.velocity.x = float(wander_direction) * wander_speed
	worker_body.move_and_slide()


func _handle_forward_obstacle(direction: float, is_wander: bool) -> ObstacleResult:
	_update_rays(direction)

	var low_obstacle := _is_low_obstacle_detected()
	var step_too_high := _is_step_too_high()
	var high_obstacle := _is_high_obstacle_detected()

	if debug_obstacles and low_obstacle:
		print(
			"Worker obstacle | low=", low_obstacle,
			" step_too_high=", step_too_high,
			" high=", high_obstacle,
			" floor=", worker_body != null and worker_body.is_on_floor(),
			" ground_time=", snappedf(ground_time, 0.01),
			" step_cd=", snappedf(step_cooldown, 0.01),
			" jump_cd=", snappedf(jump_cooldown, 0.01),
			" jump_attempts=", jump_attempts
		)

	if not low_obstacle:
		_reset_obstacle_memory()
		return ObstacleResult.NONE

	if last_obstacle_direction != 0.0 and signf(last_obstacle_direction) != signf(direction):
		_reset_obstacle_memory()

	last_obstacle_direction = direction

	if _can_step_up(step_too_high):
		_start_step_climb(direction)
		return ObstacleResult.STEPPED

	if high_obstacle or step_too_high:
		if _can_jump():
			_jump(direction)
			return ObstacleResult.JUMPED

	if is_wander and wander_turn_when_blocked:
		_turn_wander()
		return ObstacleResult.TURNED

	return ObstacleResult.BLOCKED


func _can_step_up(step_too_high: bool) -> bool:
	if not step_up_enabled:
		return false

	if step_too_high:
		return false

	if worker_body == null:
		return false

	if step_ray == null:
		return false

	if step_height_ray == null:
		return false

	if not worker_body.is_on_floor():
		return false

	if ground_time < minimum_ground_time_before_step:
		return false

	if step_cooldown > 0.0:
		return false

	return step_ray.is_colliding() and not step_height_ray.is_colliding()


func _start_step_climb(direction: float) -> void:
	step_climb_direction = direction
	step_climb_timer = step_climb_duration
	step_cooldown = step_cooldown_time
	ground_time = 0.0

	_update_step_climb(0.0)


func _update_step_climb(delta: float) -> void:
	step_climb_timer -= delta

	var base_speed := maxf(move_speed, wander_speed)

	worker_body.velocity.x = step_climb_direction * base_speed * step_climb_forward_multiplier
	worker_body.velocity.y = step_climb_vertical_velocity

	worker_body.move_and_slide()

	if step_climb_timer <= 0.0:
		_stop_step_climb()


func _stop_step_climb() -> void:
	step_climb_timer = 0.0
	step_climb_direction = 0.0


func _can_jump() -> bool:
	if not obstacle_jump_enabled:
		return false

	if worker_body == null:
		return false

	if not worker_body.is_on_floor():
		return false

	if ground_time < minimum_ground_time_before_jump:
		return false

	if jump_cooldown > 0.0:
		return false

	if jump_attempts >= max_jump_attempts_before_turn:
		return false

	return true


func _jump(direction: float) -> void:
	var base_speed := maxf(move_speed, wander_speed)

	worker_body.velocity.x = direction * base_speed * jump_forward_speed_multiplier
	worker_body.velocity.y = jump_velocity

	jump_cooldown = jump_cooldown_time
	jump_attempts += 1
	ground_time = 0.0


func _is_low_obstacle_detected() -> bool:
	if step_ray == null:
		return false

	return step_ray.is_colliding()


func _is_step_too_high() -> bool:
	if step_ray == null:
		return false

	if step_height_ray == null:
		return false

	return step_ray.is_colliding() and step_height_ray.is_colliding()


func _is_high_obstacle_detected() -> bool:
	if step_ray == null:
		return false

	if clearance_ray == null:
		return false

	return step_ray.is_colliding() and clearance_ray.is_colliding()


func _turn_wander() -> void:
	wander_direction *= -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	_stop_step_climb()
	_reset_obstacle_memory()
	_update_rays(float(wander_direction))


func _randomize_wander() -> void:
	wander_direction = 1 if randf() > 0.5 else -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	_stop_step_climb()
	_reset_obstacle_memory()
	_update_rays(float(wander_direction))


func _reset_obstacle_memory() -> void:
	jump_attempts = 0
	last_obstacle_direction = 0.0


func _apply_gravity(delta: float) -> void:
	if worker_body == null:
		return

	if not worker_body.is_on_floor():
		worker_body.velocity.y += gravity * delta
	else:
		if worker_body.velocity.y > 0.0:
			worker_body.velocity.y = 0.0


func _update_rays(direction: float) -> void:
	if step_ray != null:
		step_ray.target_position.x = absf(step_ray.target_position.x) * direction
		step_ray.force_raycast_update()

	if step_height_ray != null:
		step_height_ray.target_position.x = absf(step_height_ray.target_position.x) * direction
		step_height_ray.force_raycast_update()

	if clearance_ray != null:
		clearance_ray.target_position.x = absf(clearance_ray.target_position.x) * direction
		clearance_ray.force_raycast_update()

	if gap_ray != null:
		gap_ray.position.x = absf(gap_ray.position.x) * direction
		gap_ray.force_raycast_update()

	if floor_ray != null:
		floor_ray.force_raycast_update()


func _detect_gap() -> bool:
	if gap_ray == null:
		return false

	if worker_body == null:
		return false

	if not worker_body.is_on_floor():
		return false

	return not gap_ray.is_colliding()


func _stop_as_blocked() -> void:
	if worker_body == null:
		return

	has_target = false
	movement_mode = MovementMode.NONE
	_stop_step_climb()
	worker_body.velocity.x = 0.0
	blocked.emit()
