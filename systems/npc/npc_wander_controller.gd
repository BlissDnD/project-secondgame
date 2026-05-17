extends Node
class_name NPCWanderController

enum State {
	IDLE,
	WALKING
}

var npc: CharacterBody2D
var definition: NPCDefinition

var state: State = State.IDLE
var target_position: Vector2
var idle_timer: float = 0.0
var paused: bool = false

func setup(owner_npc: CharacterBody2D, npc_definition: NPCDefinition) -> void:
	npc = owner_npc
	definition = npc_definition
	_enter_idle()

func set_paused(value: bool) -> void:
	paused = value

	if paused and npc != null:
		npc.velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if npc == null or definition == null:
		return

	if paused:
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
		return

	match state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking()

func _process_idle(delta: float) -> void:
	idle_timer -= delta

	if idle_timer <= 0.0:
		_pick_new_target()
		state = State.WALKING

func _process_walking() -> void:
	var direction := target_position - npc.global_position

	if direction.length() <= 4.0:
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
		_enter_idle()
		return

	npc.velocity = direction.normalized() * definition.walk_speed
	npc.move_and_slide()

func _enter_idle() -> void:
	state = State.IDLE
	npc.velocity = Vector2.ZERO

	var min_time: float = definition.idle_time_min
	var max_time: float = maxf(definition.idle_time_max, min_time)

	idle_timer = randf_range(min_time, max_time)
func _pick_new_target() -> void:
	var angle := randf() * TAU
	var distance := randf_range(definition.wander_radius * 0.25, definition.wander_radius)

	var origin: Vector2 = npc.global_position

	if npc.has_method("get_spawn_position"):
		origin = npc.get_spawn_position()
	target_position = origin + Vector2(cos(angle), sin(angle)) * distance
