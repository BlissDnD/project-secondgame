extends GOAPAction
class_name GOAPMineCrystalAction

@export var mine_time: float = 1.0
@export var crystal_item_scene: PackedScene
@export var spawn_offset: Vector2 = Vector2(0, -24)

var elapsed: float = 0.0
var has_spawned: bool = false


func _init() -> void:
	action_id = &"mine_crystal"
	display_name = "Mine Crystal"
	base_cost = 0.1
	interruptible = true
	requires_target = true

	preconditions = {
		&"at_work_target": true,
		&"can_work": true,
		&"has_assignment": true,
		&"has_cargo": false,
		&"has_mined_crystal": false,
		&"stamina_low": false
	}

	effects = {
		&"has_mined_crystal": true
	}


func is_valid_for(blackboard: WorkerBlackboard) -> bool:
	return blackboard != null \
		and blackboard.worker != null \
		and blackboard.has_assignment() \
		and blackboard.has_work_target()


func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	elapsed = 0.0
	has_spawned = false
	status = ActionStatus.RUNNING

	if blackboard != null:
		blackboard.clear_mined_crystal()
		blackboard.current_item = null

	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()
		blackboard.adapter.set_working()


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail("missing_blackboard")

	if blackboard.worker == null:
		return fail("missing_worker")

	if crystal_item_scene == null:
		return fail("missing_crystal_item_scene")

	if blackboard.has_cargo():
		return fail("already_has_cargo")

	if has_spawned:
		status = ActionStatus.SUCCEEDED
		return status

	elapsed += delta

	if elapsed < mine_time:
		status = ActionStatus.RUNNING
		return status

	var item := crystal_item_scene.instantiate() as Node2D

	if item == null:
		return fail("failed_to_spawn_crystal_item")

	var world := blackboard.worker.get_tree().current_scene

	if world == null:
		return fail("missing_world_scene")

	world.add_child(item)
	item.global_position = blackboard.get_work_target_position() + spawn_offset

	blackboard.current_item = item
	blackboard.set_mined_crystal(true)

	has_spawned = true

	print("[MINE] spawned crystal item=", item)

	status = ActionStatus.SUCCEEDED
	return status


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null and blackboard.adapter != null:
		blackboard.adapter.stop_movement()

	super.exit(blackboard)
