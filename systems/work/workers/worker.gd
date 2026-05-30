extends CharacterBody2D
class_name Worker
@export var carry_controller: WorkerCarryController
@export var state_machine: WorkerStateMachine
@export var stats: WorkerStatsComponent
@export var need_system: WorkerNeedSystem
@export var goal_selector: UtilityGoalSelector
@export var movement: Node
@export var blackboard: WorkerBlackboard
@export var goap_brain: GOAPBrain
@export var goap_adapter: WorkerGOAPAdapter
var assigned_work_target: Node2D = null
@export var crystal_cargo_visual: Node2D
@export var debug_label: Label
@export var cargo_hold_point: Node2D
@export var main_crystal_group: String = "main_crystal"
@export var deposit_distance: float = 28.0
@export var gravity: float = 900.0

@export_category("Idle Wander Fallback")
@export var idle_wander_enabled: bool = false
@export var idle_wander_speed: float = 35.0
@export var idle_wander_move_time_min: float = 1.0
@export var idle_wander_move_time_max: float = 3.0
@export var idle_wander_pause_time_min: float = 0.5
@export var idle_wander_pause_time_max: float = 1.4
@export_range(0.0, 1.0, 0.01) var idle_wander_turn_chance: float = 0.35
@export var idle_wander_turn_on_wall: bool = true
@export var idle_wander_turn_on_gap: bool = true

@export_category("Idle Wander Rays")
@export var idle_floor_ray: RayCast2D
@export var idle_wall_ray: RayCast2D
@export var idle_gap_ray: RayCast2D

var current_socket: Node = null
var has_assignment: bool = false
var assigned_target: Node2D = null

var has_crystal_cargo: bool = false
var main_crystal_target: Node2D = null

var idle_wander_direction: int = 1
var idle_wander_timer: float = 0.0
var idle_wander_paused: bool = false


func _ready() -> void:
	add_to_group("worker")
	randomize()

	_resolve_nodes()
	_connect_signals()

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = false

	_randomize_idle_wander()
	set_worker_state(WorkerStateMachine.IDLE, "spawned")


func _physics_process(delta: float) -> void:
	if state_machine == null:
		return

	_update_worker_context()
	_update_lifecycle()
	_update_non_goap_state_behavior(delta)
	_update_debug_label()

func get_cargo_hold_point() -> Node2D:
	return cargo_hold_point
func _resolve_nodes() -> void:
	if state_machine == null:
		state_machine = get_node_or_null("WorkerStateMachine") as WorkerStateMachine

	if stats == null:
		stats = get_node_or_null("WorkerStatsComponent") as WorkerStatsComponent

	if need_system == null:
		need_system = get_node_or_null("WorkerNeedSystem") as WorkerNeedSystem

	if goal_selector == null:
		goal_selector = get_node_or_null("UtilityGoalSelector") as UtilityGoalSelector

	if movement == null:
		movement = get_node_or_null("WorkerMovementComponent")

	if blackboard == null:
		blackboard = get_node_or_null("WorkerBlackboard") as WorkerBlackboard

	if goap_brain == null:
		goap_brain = get_node_or_null("GOAPBrain") as GOAPBrain

	if goap_adapter == null:
		goap_adapter = get_node_or_null("WorkerGOAPAdapter") as WorkerGOAPAdapter

	if idle_floor_ray == null:
		idle_floor_ray = get_node_or_null("FloorRay") as RayCast2D

	if idle_wall_ray == null:
		idle_wall_ray = get_node_or_null("WallRay") as RayCast2D

	if idle_gap_ray == null:
		idle_gap_ray = get_node_or_null("GapRay") as RayCast2D

	if crystal_cargo_visual == null:
		crystal_cargo_visual = get_node_or_null("CrystalCargoVisual") as Node2D
		if crystal_cargo_visual == null:
			crystal_cargo_visual = get_node_or_null("CristalCargoVisual") as Node2D

	if debug_label == null:
		debug_label = get_node_or_null("DebugLabel") as Label


func _connect_signals() -> void:
	if movement != null:
		if movement.has_signal("reached_target") and not movement.reached_target.is_connected(_on_movement_reached_target):
			movement.reached_target.connect(_on_movement_reached_target)

		if movement.has_signal("blocked") and not movement.blocked.is_connected(_on_movement_blocked):
			movement.blocked.connect(_on_movement_blocked)

	if state_machine != null and not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

	if stats != null:
		if not stats.stamina_depleted.is_connected(_on_stamina_depleted):
			stats.stamina_depleted.connect(_on_stamina_depleted)

		if not stats.stamina_recovered.is_connected(_on_stamina_recovered):
			stats.stamina_recovered.connect(_on_stamina_recovered)

	if goap_brain != null:
		if not goap_brain.action_started.is_connected(_on_goap_action_started):
			goap_brain.action_started.connect(_on_goap_action_started)

		if not goap_brain.action_finished.is_connected(_on_goap_action_finished):
			goap_brain.action_finished.connect(_on_goap_action_finished)

		if not goap_brain.action_failed.is_connected(_on_goap_action_failed):
			goap_brain.action_failed.connect(_on_goap_action_failed)


func _update_worker_context() -> void:
	if blackboard != null and blackboard.has_method("update_world_state"):
		blackboard.call("update_world_state")


func _update_lifecycle() -> void:
	if stats == null or need_system == null or goal_selector == null:
		return

	var current_need := need_system.evaluate(stats, has_assignment)
	var current_goal := goal_selector.select_goal(current_need)

	if current_goal == UtilityGoalSelector.FAILED_GOAL:
		state_machine.fail("failed_goal")
		return

	if current_goal == UtilityGoalSelector.REST_GOAL:
		if not state_machine.is_recovering():
			state_machine.recover("stamina_low")
		return

	if state_machine.is_recovering():
		if stats.has_recovered_stamina():
			state_machine.return_from_recovery(has_assignment)
		return

	if current_goal == UtilityGoalSelector.WORK_GOAL:
		if state_machine.is_idle():
			set_worker_state(WorkerStateMachine.ASSIGNED, "work_goal_selected")
		return

	if current_goal == UtilityGoalSelector.IDLE_GOAL:
		if has_crystal_cargo:
			return

		if not state_machine.is_idle():
			set_worker_state(WorkerStateMachine.IDLE, "idle_goal_selected")

		return


func _update_non_goap_state_behavior(delta: float) -> void:
	match state_machine.current_state:
		WorkerStateMachine.IDLE:
			_execute_idle_fallback(delta)

		WorkerStateMachine.ASSIGNED:
			_execute_assigned()

		WorkerStateMachine.MOVING_TO_WORK:
			_execute_moving_to_work(delta)

		WorkerStateMachine.WORKING:
			_execute_working(delta)

		WorkerStateMachine.CARRYING:
			_execute_carrying(delta)

		WorkerStateMachine.DEPOSITING:
			_execute_depositing()

		WorkerStateMachine.RECOVERING:
			_execute_recovering_fallback(delta)

		WorkerStateMachine.FAILED:
			_execute_failed(delta)

		_:
			_apply_idle_physics(delta)


func _execute_idle_fallback(delta: float) -> void:
	if goap_brain != null and goap_brain.current_action != null:
		return

	if _movement_has_method(&"physics_update"):
		movement.call("physics_update", delta)
	else:
		_apply_idle_wander(delta)

	if stats != null and absf(velocity.x) > 0.1:
		stats.drain_stamina_for_movement(delta)


func _execute_assigned() -> void:
	velocity.x = 0.0

	if assigned_target != null:
		if blackboard != null:
			blackboard.set_target(assigned_target)

		set_worker_state(WorkerStateMachine.MOVING_TO_WORK, "has_assigned_target")
	else:
		set_worker_state(WorkerStateMachine.WORKING, "assigned_without_target")


func _execute_moving_to_work(delta: float) -> void:
	if goap_brain != null and goap_brain.current_action != null:
		return

	if assigned_target == null:
		set_worker_state(WorkerStateMachine.WORKING, "missing_target_continue_work")
		return

	if _movement_has_method(&"set_target"):
		movement.call("set_target", assigned_target.global_position)

	if _movement_has_method(&"physics_update"):
		movement.call("physics_update", delta)
	else:
		var direction := signf(assigned_target.global_position.x - global_position.x)
		velocity.x = direction * idle_wander_speed
		_apply_gravity(delta)
		move_and_slide()

	if stats != null:
		stats.drain_stamina_for_movement(delta)

	if global_position.distance_to(assigned_target.global_position) <= deposit_distance:
		velocity.x = 0.0
		set_worker_state(WorkerStateMachine.WORKING, "arrived_to_work")


func _execute_working(delta: float) -> void:
	if goap_brain != null and goap_brain.current_action != null:
		return

	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	velocity = Vector2.ZERO

	if stats != null:
		stats.drain_stamina_for_work(delta)


func _execute_carrying(delta: float) -> void:
	if goap_brain != null and goap_brain.current_action != null:
		_try_deposit_crystal()
		return

	if main_crystal_target != null and _movement_has_method(&"set_target"):
		movement.call("set_target", main_crystal_target.global_position)

	if _movement_has_method(&"physics_update"):
		movement.call("physics_update", delta)
	else:
		_apply_gravity(delta)
		move_and_slide()

	if stats != null:
		stats.drain_stamina_for_movement(delta)

	_try_deposit_crystal()


func _execute_depositing() -> void:
	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	velocity = Vector2.ZERO


func _execute_recovering_fallback(delta: float) -> void:
	if goap_brain != null and goap_brain.current_action != null:
		return

	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	velocity.x = 0.0
	_apply_gravity(delta)
	move_and_slide()

	if stats != null:
		stats.recover_stamina(delta)


func _execute_failed(delta: float) -> void:
	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	velocity.x = 0.0
	_apply_gravity(delta)
	move_and_slide()


func set_worker_state(new_state: StringName, reason: String = "") -> void:
	if state_machine == null:
		return

	state_machine.set_state(new_state, reason)


func get_worker_state() -> StringName:
	if state_machine == null:
		return &"None"

	return state_machine.current_state


func assign_work(target: Node2D) -> void:
	assigned_work_target = target
	has_assignment = target != null

	if blackboard != null:
		blackboard.set_assignment(target)

	if state_machine != null:
		state_machine.set_state(
			WorkerStateMachine.ASSIGNED,
			"work_assigned"
		)

func clear_assignment() -> void:
	assigned_work_target = null
	has_assignment = false

	if blackboard != null:
		blackboard.clear_assignment()

	if state_machine != null:
		state_machine.set_state(
			WorkerStateMachine.IDLE,
			"assignment_cleared"
		)

func apply_work_drain(delta: float) -> void:
	if stats != null:
		stats.drain_stamina_for_work(delta)


func receive_crystal_cargo() -> void:
	has_crystal_cargo = true
	has_assignment = true

	if stats != null:
		stats.add_carry_weight(1.0)

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = true

	main_crystal_target = _find_main_crystal()

	if main_crystal_target == null:
		set_worker_state(WorkerStateMachine.FAILED, "cannot_reach_main_crystal")
		return

	if blackboard != null:
		blackboard.set_target(main_crystal_target)

	if _movement_has_method(&"set_target"):
		movement.call("set_target", main_crystal_target.global_position)

	set_worker_state(WorkerStateMachine.CARRYING, "carrying_crystal_to_main")


func on_inserted_into_socket(socket: Node) -> void:
	current_socket = socket
	velocity = Vector2.ZERO

	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	assign_work(socket as Node2D)


func on_removed_from_socket(socket: Node) -> void:
	if current_socket == socket:
		current_socket = null

	clear_assignment()


func on_picked_up() -> void:
	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	set_worker_state(WorkerStateMachine.FAILED, "picked_up_by_player")
	velocity = Vector2.ZERO


func on_dropped() -> void:
	if _movement_has_method(&"clear_target"):
		movement.call("clear_target")

	velocity = Vector2.ZERO
	set_worker_state(WorkerStateMachine.IDLE, "dropped_by_player")


func _movement_has_method(method_name: StringName) -> bool:
	return movement != null and movement.has_method(method_name)


func _apply_idle_wander(delta: float) -> void:
	if not idle_wander_enabled:
		_apply_idle_physics(delta)
		return

	idle_wander_timer -= delta

	if idle_wander_paused:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()

		if idle_wander_timer <= 0.0:
			idle_wander_paused = false
			idle_wander_timer = randf_range(idle_wander_move_time_min, idle_wander_move_time_max)
			_update_idle_wander_rays()

		return

	if _idle_wander_should_turn():
		_turn_idle_wander()
	elif idle_wander_timer <= 0.0:
		if randf() < idle_wander_turn_chance:
			_turn_idle_wander()
		else:
			idle_wander_paused = true
			idle_wander_timer = randf_range(idle_wander_pause_time_min, idle_wander_pause_time_max)

	velocity.x = idle_wander_direction * idle_wander_speed
	_apply_gravity(delta)
	move_and_slide()


func _idle_wander_should_turn() -> bool:
	if idle_wander_turn_on_wall:
		if idle_wall_ray != null and idle_wall_ray.enabled and idle_wall_ray.is_colliding():
			return true

	if idle_wander_turn_on_gap:
		if idle_gap_ray != null and idle_gap_ray.enabled and not idle_gap_ray.is_colliding():
			return true

	return false


func _turn_idle_wander() -> void:
	idle_wander_direction *= -1
	idle_wander_timer = randf_range(idle_wander_move_time_min, idle_wander_move_time_max)
	idle_wander_paused = false
	_update_idle_wander_rays()


func _randomize_idle_wander() -> void:
	idle_wander_direction = 1 if randf() > 0.5 else -1
	idle_wander_timer = randf_range(idle_wander_move_time_min, idle_wander_move_time_max)
	idle_wander_paused = false
	_update_idle_wander_rays()


func _update_idle_wander_rays() -> void:
	if idle_wall_ray != null:
		idle_wall_ray.target_position.x = absf(idle_wall_ray.target_position.x) * float(idle_wander_direction)

	if idle_gap_ray != null:
		idle_gap_ray.position.x = absf(idle_gap_ray.position.x) * float(idle_wander_direction)


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

	if global_position.distance_to(main_crystal_target.global_position) > deposit_distance:
		return

	set_worker_state(WorkerStateMachine.DEPOSITING, "depositing_crystal")

	if main_crystal_target.has_method("deposit_crystal"):
		main_crystal_target.deposit_crystal(1)

	has_crystal_cargo = false
	has_assignment = false

	if stats != null:
		stats.clear_carry_weight()

	if crystal_cargo_visual != null:
		crystal_cargo_visual.visible = false

	main_crystal_target = null

	if blackboard != null:
		blackboard.clear_target()

	set_worker_state(WorkerStateMachine.IDLE, "crystal_deposited")


func _find_main_crystal() -> Node2D:
	var nodes := get_tree().get_nodes_in_group(main_crystal_group)

	for node in nodes:
		if node is Node2D:
			return node

	return null


func _on_movement_reached_target() -> void:
	_try_deposit_crystal()


func _on_movement_blocked() -> void:
	if get_worker_state() == WorkerStateMachine.CARRYING:
		set_worker_state(WorkerStateMachine.FAILED, "blocked_cannot_reach_main_crystal")


func _on_stamina_depleted() -> void:
	if state_machine != null:
		state_machine.recover("stamina_depleted")


func _on_stamina_recovered() -> void:
	if state_machine != null and state_machine.is_recovering():
		state_machine.return_from_recovery(has_assignment)


func _on_state_changed(old_state: StringName, new_state: StringName, reason: String = "") -> void:
	print("Worker state changed: ", old_state, " -> ", new_state, " reason=", reason)

	if new_state == WorkerStateMachine.IDLE:
		_randomize_idle_wander()


func _on_goap_action_started(action: GOAPAction) -> void:
	print("GOAP action started: ", action.action_id)


func _on_goap_action_finished(action: GOAPAction) -> void:
	print("GOAP action finished: ", action.action_id)

	if blackboard != null:
		blackboard.set_action_result(action.action_id, &"finished", "")


func _on_goap_action_failed(action: GOAPAction) -> void:
	print("GOAP action failed: ", action.action_id, " reason=", action.last_failure_reason)

	if blackboard != null:
		blackboard.set_action_result(action.action_id, &"failed", action.last_failure_reason)


func _update_debug_label() -> void:
	if debug_label == null:
		return

	var state_text := "State: " + str(get_worker_state())

	if need_system != null:
		state_text += "\nNeed: " + str(need_system.current_need)

	if goal_selector != null:
		state_text += "\nGoal: " + str(goal_selector.current_goal)

	if goap_brain != null:
		state_text += "\nAction: "
		state_text += str(goap_brain.current_action.action_id) if goap_brain.current_action != null else "None"

	if stats != null:
		state_text += "\nHP: " + str(roundi(stats.health))
		state_text += "\nStamina: " + str(roundi(stats.stamina))
		state_text += "\nEnergy: " + str(roundi(stats.energy))
		state_text += "\nCarry: " + str(stats.carry_weight) + "/" + str(stats.max_carry_weight)

	if has_crystal_cargo:
		state_text += "\nCargo: Crystal"

	if has_assignment:
		state_text += "\nAssignment: yes"

	if blackboard != null:
		state_text += "\nVisible Item: " + str(
			blackboard.has_visible_haulable_item()
		)

		state_text += "\nVisible Crystal: " + str(
			blackboard.has_visible_item_type(&"crystal")
		)

		var nearest_item := blackboard.get_nearest_visible_item(&"crystal")

		state_text += "\nNearest Crystal: " + str(
			nearest_item != null
		)

		if nearest_item != null:
			var dist := global_position.distance_to(
				nearest_item.global_position
			)

			state_text += "\nCrystal Dist: " + str(roundi(dist))

	debug_label.text = state_text

func get_debug_state() -> Dictionary:
	var nearest_item: WorldItem = null

	if blackboard != null:
		nearest_item = blackboard.get_nearest_visible_item(&"crystal")

	return {
		"type": "worker",

		"state": str(get_worker_state()),
		"need": str(need_system.current_need) if need_system != null else "none",
		"goal": str(goal_selector.current_goal) if goal_selector != null else "none",
		"action": str(goap_brain.current_action.action_id)
			if goap_brain != null
			and goap_brain.current_action != null
			else "none",

		"health": stats.health if stats != null else 0,
		"energy": stats.energy if stats != null else 0,
		"stamina": stats.stamina if stats != null else 0,

		"carry_weight": stats.carry_weight if stats != null else 0,
		"max_carry_weight": stats.max_carry_weight if stats != null else 0,

		"has_assignment": has_assignment,
		"has_crystal_cargo": has_crystal_cargo,

		"visible_item": blackboard.has_visible_haulable_item()
			if blackboard != null
			else false,

		"visible_crystal": blackboard.has_visible_item_type(&"crystal")
			if blackboard != null
			else false,

		"nearest_crystal": nearest_item != null,

		"interrupt": state_machine.reason_for_interrupt
			if state_machine != null
			else "",

		"fail": state_machine.last_failure_reason
			if state_machine != null
			else "",

		"blackboard": blackboard.get_debug_state()
			if blackboard != null
			else {},

		"goap": goap_brain.get_debug_state()
			if goap_brain != null
			else {}
	}
