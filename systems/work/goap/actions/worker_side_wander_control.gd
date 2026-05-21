extends Node
class_name WorkerSideWanderMotor

signal direction_changed(direction: int)

@export var actor_path: NodePath = NodePath("..")
@export var floor_ray_path: NodePath = NodePath("../FloorRay")
@export var wall_ray_path: NodePath = NodePath("../WallRay")
@export var gap_ray_path: NodePath = NodePath("../GapRay")

@export var move_speed: float = 45.0
@export var gravity: float = 980.0
@export var turn_delay_min: float = 1.0
@export var turn_delay_max: float = 3.0
@export var pause_chance: float = 0.25
@export var pause_time_min: float = 0.4
@export var pause_time_max: float = 1.2

var actor: CharacterBody2D
var floor_ray: RayCast2D
var wall_ray: RayCast2D
var gap_ray: RayCast2D

var direction: int = 1
var active: bool = false
var timer: float = 0.0
var paused: bool = false

func _ready() -> void:
	actor = get_node_or_null(actor_path) as CharacterBody2D
	floor_ray = get_node_or_null(floor_ray_path) as RayCast2D
	wall_ray = get_node_or_null(wall_ray_path) as RayCast2D
	gap_ray = get_node_or_null(gap_ray_path) as RayCast2D

	if actor == null:
		push_error("WorkerSideWanderMotor missing actor_path.")
	if floor_ray == null:
		push_warning("WorkerSideWanderMotor missing floor_ray_path.")
	if wall_ray == null:
		push_warning("WorkerSideWanderMotor missing wall_ray_path.")
	if gap_ray == null:
		push_warning("WorkerSideWanderMotor missing gap_ray_path.")

	randomize()
	direction = 1 if randf() > 0.5 else -1
	timer = randf_range(turn_delay_min, turn_delay_max)
	_update_ray_direction()

func start() -> void:
	active = true
	paused = false
	timer = randf_range(turn_delay_min, turn_delay_max)
	_update_ray_direction()

func stop() -> void:
	active = false
	paused = false
	if actor != null:
		actor.velocity.x = 0.0

func _physics_process(delta: float) -> void:
	if actor == null:
		return

	if not actor.is_on_floor():
		actor.velocity.y += gravity * delta

	if not active:
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, move_speed)
		actor.move_and_slide()
		return

	timer -= delta

	if paused:
		actor.velocity.x = move_toward(actor.velocity.x, 0.0, move_speed)
		if timer <= 0.0:
			paused = false
			timer = randf_range(turn_delay_min, turn_delay_max)
		actor.move_and_slide()
		return

	if _should_turn():
		_turn_around()
	elif timer <= 0.0:
		if randf() < pause_chance:
			paused = true
			timer = randf_range(pause_time_min, pause_time_max)
		else:
			_turn_around()

	actor.velocity.x = direction * move_speed
	actor.move_and_slide()

func _should_turn() -> bool:
	if wall_ray != null and wall_ray.is_colliding():
		return true

	# Ha a gap_ray nem talál padlót előtte, ne menjen szakadékba.
	if gap_ray != null and not gap_ray.is_colliding():
		return true

	return false

func _turn_around() -> void:
	direction *= -1
	timer = randf_range(turn_delay_min, turn_delay_max)
	_update_ray_direction()
	direction_changed.emit(direction)

func _update_ray_direction() -> void:
	if wall_ray != null:
		wall_ray.target_position.x = abs(wall_ray.target_position.x) * direction

	if gap_ray != null:
		gap_ray.position.x = abs(gap_ray.position.x) * direction
