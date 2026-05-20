extends Node
class_name WorkerMovementComponent

signal reached_target
signal blocked

@export var worker_body: CharacterBody2D
@export var floor_ray: RayCast2D
@export var wall_ray: RayCast2D
@export var gap_ray: RayCast2D

@export var move_speed: float = 70.0
@export var jump_velocity: float = -260.0
@export var gravity: float = 900.0

@export var target_reach_distance: float = 18.0
@export var max_jumpable_wall_height_tiles: int = 1

var target_position: Vector2
var has_target: bool = false
var blocked_cooldown: float = 0.0


func set_target(position: Vector2) -> void:
	target_position = position
	has_target = true
	blocked_cooldown = 0.0


func clear_target() -> void:
	has_target = false


func physics_update(delta: float) -> void:
	if worker_body == null:
		return

	if blocked_cooldown > 0.0:
		blocked_cooldown -= delta

	if not worker_body.is_on_floor():
		worker_body.velocity.y += gravity * delta

	if not has_target:
		worker_body.velocity.x = move_toward(worker_body.velocity.x, 0.0, move_speed)
		worker_body.move_and_slide()
		return

	var distance_to_target := worker_body.global_position.distance_to(target_position)

	if distance_to_target <= target_reach_distance:
		worker_body.velocity.x = 0.0
		worker_body.move_and_slide()
		has_target = false
		reached_target.emit()
		return

	var direction := signf(target_position.x - worker_body.global_position.x)

	if direction == 0.0:
		direction = 1.0

	worker_body.velocity.x = direction * move_speed

	_update_rays(direction)

	if _detect_gap():
		_stop_as_blocked()
		return

	if _detect_wall():
		if worker_body.is_on_floor():
			worker_body.velocity.y = jump_velocity
		else:
			_stop_as_blocked()
			return

	worker_body.move_and_slide()


func _update_rays(direction: float) -> void:
	if wall_ray != null:
		wall_ray.target_position.x = abs(wall_ray.target_position.x) * direction
		wall_ray.force_raycast_update()

	if gap_ray != null:
		gap_ray.position.x = abs(gap_ray.position.x) * direction
		gap_ray.force_raycast_update()

	if floor_ray != null:
		floor_ray.force_raycast_update()


func _detect_gap() -> bool:
	if gap_ray == null:
		return false

	if not worker_body.is_on_floor():
		return false

	return not gap_ray.is_colliding()


func _detect_wall() -> bool:
	if wall_ray == null:
		return false

	return wall_ray.is_colliding()


func _stop_as_blocked() -> void:
	if blocked_cooldown > 0.0:
		return

	has_target = false
	worker_body.velocity.x = 0.0
	worker_body.move_and_slide()
	blocked_cooldown = 0.5
	blocked.emit()
