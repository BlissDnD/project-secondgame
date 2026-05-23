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
	STEPPED_UP,
	JUMPED,
	TURNED,
	BLOCKED
}

@export var worker_body: CharacterBody2D
@export var floor_ray: RayCast2D
@export var wall_ray: RayCast2D
@export var gap_ray: RayCast2D

@export_category("Horizontal Movement")
@export var move_speed: float = 70.0
@export var wander_speed: float = 45.0
@export var gravity: float = 900.0
@export var target_reach_distance: float = 18.0

@export_category("Step Up")
@export var step_up_enabled: bool = true
@export var max_step_height: float = 32.0
@export var step_check_forward_distance: float = 8.0
@export var step_up_pixel_increment: float = 1.0

@export_category("Smooth Step")
@export var smooth_step_enabled: bool = true
@export var step_smooth_speed: float = 90.0

@export_category("Jump")
@export var obstacle_jump_enabled: bool = false
@export var jump_velocity: float = -380.0
@export var jump_cooldown_time: float = 1.0
@export var minimum_ground_time_before_jump: float = 0.15
@export var failed_jump_timeout: float = 0.9
@export var max_jump_attempts_before_turn: int = 1

@export_category("Wander")
@export var wander_move_time_min: float = 1.0
@export var wander_move_time_max: float = 3.0
@export var wander_pause_time_min: float = 0.5
@export var wander_pause_time_max: float = 1.4
@export_range(0.0, 1.0, 0.01) var wander_turn_chance: float = 0.35
@export var wander_turn_on_gap: bool = false
@export var wander_jump_on_wall: bool = false
@export var wander_turn_when_blocked: bool = true

var target_position: Vector2
var has_target: bool = false
var movement_mode: MovementMode = MovementMode.NONE

var wander_direction: int = 1
var wander_timer: float = 0.0
var wander_paused: bool = false

var jump_cooldown: float = 0.0
var ground_time: float = 0.0
var jump_attempts_on_current_obstacle: int = 0
var jump_attempt_timer: float = 0.0
var last_obstacle_direction: float = 0.0

var pending_step_up_height: float = 0.0


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
	pending_step_up_height = 0.0
	_reset_obstacle_memory()

	if worker_body != null:
		worker_body.velocity.x = 0.0


func physics_update(delta: float) -> void:
	if worker_body == null:
		return

	_update_timers(delta)
	_apply_gravity(delta)
	_apply_smooth_step(delta)

	match movement_mode:
		MovementMode.TARGET:
			_target_update(delta)

		MovementMode.WANDER:
			_wander_update(delta)

		MovementMode.NONE:
			worker_body.velocity.x = 0.0
			worker_body.move_and_slide()


func _update_timers(delta: float) -> void:
	if jump_cooldown > 0.0:
		jump_cooldown -= delta

	if jump_attempt_timer > 0.0:
		jump_attempt_timer -= delta
	else:
		jump_attempts_on_current_obstacle = 0

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

	var handled := _handle_forward_obstacle(direction, false)
	if handled == ObstacleResult.BLOCKED:
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

	if wander_turn_on_gap:
		_update_rays(direction)
		if _detect_gap():
			_turn_wander()
			worker_body.move_and_slide()
			return

	var handled := _handle_forward_obstacle(direction, true)
	if handled == ObstacleResult.TURNED:
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

	if not _detect_wall():
		_reset_obstacle_memory()
		return ObstacleResult.NONE

	if step_up_enabled and worker_body.is_on_floor():
		if _try_step_up(direction):
			return ObstacleResult.STEPPED_UP

	if obstacle_jump_enabled and worker_body.is_on_floor():
		if _can_try_jump_for_obstacle(direction):
			_jump_for_obstacle(direction)
			return ObstacleResult.JUMPED

	if is_wander and wander_turn_when_blocked:
		_turn_wander()
		return ObstacleResult.TURNED

	return ObstacleResult.BLOCKED


func _try_step_up(direction: float) -> bool:
	if worker_body == null:
		return false

	if not worker_body.is_on_floor():
		return false

	var original_position := worker_body.global_position
	var original_transform := worker_body.transform
	var forward_offset := Vector2(direction * step_check_forward_distance, 0.0)

	var found_height := 0.0
	var height := step_up_pixel_increment

	while height <= max_step_height:
		var test_position := original_position + Vector2(0.0, -height)

		worker_body.global_position = test_position
		worker_body.force_update_transform()

		var can_move_forward := not worker_body.test_move(worker_body.transform, forward_offset)

		if can_move_forward:
			found_height = height
			break

		height += step_up_pixel_increment

	worker_body.global_position = original_position
	worker_body.transform = original_transform
	worker_body.force_update_transform()

	if found_height <= 0.0:
		return false

	if smooth_step_enabled:
		pending_step_up_height = maxf(pending_step_up_height, found_height)
	else:
		worker_body.global_position.y -= found_height

	return true


func _apply_smooth_step(delta: float) -> void:
	if worker_body == null:
		return

	if pending_step_up_height <= 0.0:
		return

	var amount := step_smooth_speed * delta
	amount = minf(amount, pending_step_up_height)

	worker_body.global_position.y -= amount
	pending_step_up_height -= amount

	if pending_step_up_height <= 0.1:
		pending_step_up_height = 0.0


func _can_try_jump_for_obstacle(direction: float) -> bool:
	if not wander_jump_on_wall:
		return false

	if not worker_body.is_on_floor():
		return false

	if ground_time < minimum_ground_time_before_jump:
		return false

	if jump_cooldown > 0.0:
		return false

	if last_obstacle_direction != 0.0 and signf(last_obstacle_direction) != signf(direction):
		jump_attempts_on_current_obstacle = 0

	if jump_attempts_on_current_obstacle >= max_jump_attempts_before_turn:
		return false

	return true


func _jump_for_obstacle(direction: float) -> void:
	worker_body.velocity.y = jump_velocity
	jump_cooldown = jump_cooldown_time
	ground_time = 0.0
	jump_attempts_on_current_obstacle += 1
	jump_attempt_timer = failed_jump_timeout
	last_obstacle_direction = direction


func _turn_wander() -> void:
	wander_direction *= -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	pending_step_up_height = 0.0
	_reset_obstacle_memory()
	_update_rays(float(wander_direction))


func _randomize_wander() -> void:
	wander_direction = 1 if randf() > 0.5 else -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	pending_step_up_height = 0.0
	_reset_obstacle_memory()
	_update_rays(float(wander_direction))


func _reset_obstacle_memory() -> void:
	jump_attempts_on_current_obstacle = 0
	jump_attempt_timer = 0.0
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
	if wall_ray != null:
		wall_ray.target_position.x = absf(wall_ray.target_position.x) * direction
		wall_ray.force_raycast_update()

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


func _detect_wall() -> bool:
	if wall_ray == null:
		return false

	return wall_ray.is_colliding()


func _stop_as_blocked() -> void:
	if worker_body == null:
		return

	has_target = false
	movement_mode = MovementMode.NONE
	pending_step_up_height = 0.0
	worker_body.velocity.x = 0.0
	blocked.emit()
