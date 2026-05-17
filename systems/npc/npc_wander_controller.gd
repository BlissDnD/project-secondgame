extends Node
class_name NPCWanderController

enum State {
	IDLE,
	WALKING
}

@export var gravity: float = 980.0
@export var edge_check_distance: float = 14.0
@export var wall_check_distance: float = 10.0
@export var floor_check_distance: float = 22.0

var npc: CharacterBody2D
var definition: NPCDefinition

var state: State = State.IDLE
var idle_timer: float = 0.0
var walk_timer: float = 0.0
var move_direction: float = 1.0
var paused: bool = false


func setup(owner_npc: CharacterBody2D, npc_definition: NPCDefinition) -> void:
	npc = owner_npc
	definition = npc_definition
	_enter_idle()


func set_paused(value: bool) -> void:
	paused = value

	if paused and npc != null:
		npc.velocity.x = 0.0


func _physics_process(delta: float) -> void:
	if npc == null or definition == null:
		return

	_apply_gravity(delta)

	if paused:
		npc.velocity.x = 0.0
		npc.move_and_slide()
		return

	match state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)

	npc.move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not npc.is_on_floor():
		npc.velocity.y += gravity * delta
	else:
		if npc.velocity.y > 0.0:
			npc.velocity.y = 0.0


func _process_idle(delta: float) -> void:
	npc.velocity.x = 0.0
	idle_timer -= delta

	if idle_timer <= 0.0:
		_enter_walking()


func _process_walking(delta: float) -> void:
	walk_timer -= delta

	if walk_timer <= 0.0:
		_enter_idle()
		return

	if _should_turn_around():
		move_direction *= -1.0

	npc.velocity.x = move_direction * definition.walk_speed


func _enter_idle() -> void:
	state = State.IDLE
	npc.velocity.x = 0.0

	var min_time: float = definition.idle_time_min
	var max_time: float = maxf(definition.idle_time_max, min_time)

	idle_timer = randf_range(min_time, max_time)


func _enter_walking() -> void:
	state = State.WALKING

	if randf() < 0.5:
		move_direction = -1.0
	else:
		move_direction = 1.0

	walk_timer = randf_range(1.0, 3.0)


func _should_turn_around() -> bool:
	if not npc.is_on_floor():
		return false

	if npc.is_on_wall():
		return true

	if _is_too_far_from_spawn():
		return true

	if not _has_floor_ahead():
		return true

	return false


func _is_too_far_from_spawn() -> bool:
	var spawn_position: Vector2 = npc.global_position

	if npc.has_method("get_spawn_position"):
		spawn_position = npc.call("get_spawn_position") as Vector2

	var distance_from_spawn: float = npc.global_position.x - spawn_position.x

	if absf(distance_from_spawn) >= definition.wander_radius:
		if signf(distance_from_spawn) == move_direction:
			return true

	return false


func _has_floor_ahead() -> bool:
	var space_state := npc.get_world_2d().direct_space_state

	var from := npc.global_position + Vector2(edge_check_distance * move_direction, 0.0)
	var to := from + Vector2.DOWN * floor_check_distance

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [npc]

	var result := space_state.intersect_ray(query)

	return not result.is_empty()
