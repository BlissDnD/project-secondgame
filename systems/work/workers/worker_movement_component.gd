extends Node
class_name WorkerMovementComponent

signal reached_target
signal blocked

enum MovementMode {
	NONE,
	TARGET,
	WANDER
}

@export var worker_body: CharacterBody2D
@export var floor_ray: RayCast2D
@export var wall_ray: RayCast2D
@export var gap_ray: RayCast2D

@export_category("Target Movement")
@export var move_speed: float = 70.0
@export var jump_velocity: float = -260.0
@export var gravity: float = 900.0
@export var target_reach_distance: float = 18.0
@export var max_jumpable_wall_height_tiles: int = 1

@export_category("Wander")
@export var wander_speed: float = 35.0
@export var wander_move_time_min: float = 1.0
@export var wander_move_time_max: float = 3.0
@export var wander_pause_time_min: float = 0.5
@export var wander_pause_time_max: float = 1.4
@export_range(0.0, 1.0, 0.01) var wander_turn_chance: float = 0.35
@export var wander_turn_on_wall: bool = true
@export var wander_turn_on_gap: bool = true

var target_position: Vector2
var has_target: bool = false
var blocked_cooldown: float = 0.0

var movement_mode: MovementMode = MovementMode.NONE

var wander_direction: int = 1
var wander_timer: float = 0.0
var wander_paused: bool = false


func _ready() -> void:
	randomize()

	if worker_body == null:
		worker_body = get_parent() as CharacterBody2D

	_randomize_wander()


func set_target(position: Vector2) -> void:
	target_position = position
	has_target = true
	blocked_cooldown = 0.0
	movement_mode = MovementMode.TARGET


func clear_target() -> void:
	has_target = false

	if movement_mode == MovementMode.TARGET:
		movement_mode = MovementMode.NONE

	if worker_body != null:
		worker_body.velocity.x = 0.0


func start_wander() -> void:
	has_target = false
	movement_mode = MovementMode.WANDER
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

	if worker_body != null:
		worker_body.velocity.x = 0.0


func physics_update(delta: float) -> void:
	if worker_body == null:
		return

	if blocked_cooldown > 0.0:
		blocked_cooldown -= delta

	_apply_gravity(delta)

	match movement_mode:
		MovementMode.TARGET:
			_target_update(delta)

		MovementMode.WANDER:
			_wander_update(delta)

		MovementMode.NONE:
			worker_body.velocity.x = 0.0
			worker_body.move_and_slide()


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

	worker_body.velocity.x = direction * move_speed

	_update_rays(direction)

	if _detect_gap():
		_stop_as_blocked()
		worker_body.move_and_slide()
		return

	if _detect_wall():
		if worker_body.is_on_floor():
			worker_body.velocity.y = jump_velocity
		else:
			_stop_as_blocked()
			worker_body.move_and_slide()
			return

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

	if _wander_should_turn():
		_turn_wander()
	elif wander_timer <= 0.0:
		if randf() < wander_turn_chance:
			_turn_wander()
		else:
			wander_paused = true
			wander_timer = randf_range(wander_pause_time_min, wander_pause_time_max)

	worker_body.velocity.x = wander_direction * wander_speed
	_update_rays(float(wander_direction))
	worker_body.move_and_slide()


func _wander_should_turn() -> bool:
	_update_rays(float(wander_direction))

	if wander_turn_on_wall:
		if wall_ray != null and wall_ray.enabled and wall_ray.is_colliding():
			return true

	if wander_turn_on_gap:
		if gap_ray != null and gap_ray.enabled and worker_body != null and worker_body.is_on_floor():
			if not gap_ray.is_colliding():
				return true

	return false


func _turn_wander() -> void:
	wander_direction *= -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	_update_rays(float(wander_direction))


func _randomize_wander() -> void:
	wander_direction = 1 if randf() > 0.5 else -1
	wander_timer = randf_range(wander_move_time_min, wander_move_time_max)
	wander_paused = false
	_update_rays(float(wander_direction))


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

	if blocked_cooldown > 0.0:
		return

	has_target = false
	movement_mode = MovementMode.NONE
	worker_body.velocity.x = 0.0
	blocked_cooldown = 0.5
	blocked.emit()
