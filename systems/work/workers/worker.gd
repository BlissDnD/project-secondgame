extends CharacterBody2D
class_name Worker

@export var state_machine: WorkerStateMachine
@export var needs: WorkerNeedsComponent
@export var movement: WorkerMovementComponent

@export var crystal_cargo_visual: Node2D
@export var debug_label: Label

@export var main_crystal_group: String = "main_crystal"
@export var deposit_distance: float = 28.0

@export var gravity: float = 900.0

var current_socket: Node
var has_crystal_cargo: bool = false
var main_crystal_target: Node2D


func _ready() -> void:
	add_to_group("worker")

	if state_machine == null:
		state_machine = get_node_or_null("WorkerStateMachine")

	if needs == null:
		needs = get_node_or_null("WorkerNeedsComponent")

	if movement == null:
		movement = get_node_or_null("WorkerMovementComponent")

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = false

	if movement != null:
		if not movement.reached_target.is_connected(_on_movement_reached_target):
			movement.reached_target.connect(_on_movement_reached_target)

		if not movement.blocked.is_connected(_on_movement_blocked):
			movement.blocked.connect(_on_movement_blocked)

	if state_machine != null:
		if not state_machine.state_changed.is_connected(_on_state_changed):
			state_machine.state_changed.connect(_on_state_changed)

	set_worker_state(WorkerStateMachine.IDLE)


func _physics_process(delta: float) -> void:
	_update_needs(delta)
	_update_state_behavior(delta)
	_update_debug_label()


func set_worker_state(new_state: StringName) -> void:
	if state_machine == null:
		return

	state_machine.set_state(new_state)


func get_worker_state() -> StringName:
	if state_machine == null:
		return &""

	return state_machine.current_state


func apply_work_drain(delta: float) -> void:
	if needs != null:
		needs.apply_work_decay(delta)


func receive_crystal_cargo() -> void:
	has_crystal_cargo = true

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = true

	main_crystal_target = _find_main_crystal()

	if main_crystal_target == null:
		set_worker_state(WorkerStateMachine.BLOCKED_CANNOT_REACH_MAIN_CRYSTAL)
		return

	if movement != null:
		movement.set_target(main_crystal_target.global_position)

	set_worker_state(WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN)


func on_inserted_into_socket(socket: Node) -> void:
	current_socket = socket
	velocity = Vector2.ZERO

	if movement != null:
		movement.clear_target()


func on_removed_from_socket(socket: Node) -> void:
	if current_socket == socket:
		current_socket = null

	if get_worker_state() != WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN:
		set_worker_state(WorkerStateMachine.IDLE)


func on_picked_up() -> void:
	if movement != null:
		movement.clear_target()

	set_worker_state(WorkerStateMachine.CARRIED)
	velocity = Vector2.ZERO


func on_dropped() -> void:
	if movement != null:
		movement.clear_target()

	velocity = Vector2.ZERO
	set_worker_state(WorkerStateMachine.IDLE)


func _update_needs(delta: float) -> void:
	if needs == null or state_machine == null:
		return

	match state_machine.current_state:
		WorkerStateMachine.IDLE:
			needs.apply_idle_decay(delta)

		WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN:
			needs.apply_idle_decay(delta)

		WorkerStateMachine.SLEEPING:
			needs.apply_sleep_restore(delta)

		_:
			pass


func _update_state_behavior(delta: float) -> void:
	if state_machine == null:
		return

	match state_machine.current_state:
		WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN:
			if movement != null:
				movement.physics_update(delta)

			_try_deposit_crystal()

		WorkerStateMachine.IDLE:
			if movement != null:
				movement.clear_target()

			_apply_idle_physics(delta)

		WorkerStateMachine.BLOCKED_CANNOT_REACH_MAIN_CRYSTAL:
			if movement != null:
				movement.clear_target()

			velocity.x = 0.0
			_apply_gravity(delta)
			move_and_slide()

		WorkerStateMachine.CARRIED:
			if movement != null:
				movement.clear_target()

			velocity = Vector2.ZERO

		WorkerStateMachine.WORKING_CRYSTAL_NODE:
			if movement != null:
				movement.clear_target()

			velocity = Vector2.ZERO

		WorkerStateMachine.DEPOSITING_CRYSTAL:
			if movement != null:
				movement.clear_target()

			velocity = Vector2.ZERO

		WorkerStateMachine.SLEEPING:
			if movement != null:
				movement.clear_target()

			_apply_idle_physics(delta)

		_:
			velocity.x = 0.0
			_apply_gravity(delta)
			move_and_slide()


func _apply_idle_physics(delta: float) -> void:
	velocity.x = 0.0
	_apply_gravity(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		return

	if velocity.y > 0.0:
		velocity.y = 0.0


func _try_deposit_crystal() -> void:
	if not has_crystal_cargo:
		return

	if main_crystal_target == null:
		return

	var distance := global_position.distance_to(main_crystal_target.global_position)

	if distance > deposit_distance:
		return

	set_worker_state(WorkerStateMachine.DEPOSITING_CRYSTAL)

	if main_crystal_target.has_method("deposit_crystal"):
		main_crystal_target.deposit_crystal(1)

	has_crystal_cargo = false

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = false

	main_crystal_target = null
	set_worker_state(WorkerStateMachine.IDLE)


func _find_main_crystal() -> Node2D:
	var nodes := get_tree().get_nodes_in_group(main_crystal_group)

	if nodes.is_empty():
		return null

	for node in nodes:
		if node is Node2D:
			return node

	return null


func _on_movement_reached_target() -> void:
	_try_deposit_crystal()


func _on_movement_blocked() -> void:
	if get_worker_state() == WorkerStateMachine.CARRYING_CRYSTAL_TO_MAIN:
		set_worker_state(WorkerStateMachine.BLOCKED_CANNOT_REACH_MAIN_CRYSTAL)


func _on_state_changed(old_state: StringName, new_state: StringName) -> void:
	print("Worker state changed: ", old_state, " -> ", new_state)


func _update_debug_label() -> void:
	if debug_label == null:
		return

	var state_text := "State: " + str(get_worker_state())

	if needs != null:
		state_text += "\n" + needs.get_debug_text()

	if has_crystal_cargo:
		state_text += "\nCargo: Crystal"

	debug_label.text = state_text
