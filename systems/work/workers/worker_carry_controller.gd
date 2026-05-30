extends Node
class_name WorkerCarryController

@export var worker_body: Node2D
@export var blackboard: WorkerBlackboard
@export var hold_point: Node2D
@export var pickup_range: float = 48.0
@export var lift_strength: float = 25.0
@export var carry_strength: float = 30.0

@export var interaction_area_path: NodePath

var interaction_area: Area2D

func _ready() -> void:
	interaction_area = get_node_or_null(interaction_area_path)
	

func can_pickup_item(item: WorldItem) -> bool:
	if item == null:
		return false

	if interaction_area == null:
		return false

	if not item.can_be_hauled_by(worker_body):
		return false

	var carryable := item.get_carryable_component()

	if carryable == null:
		return false

	if not carryable.can_be_lifted_by(lift_strength):
		return false

	var body := item.get_physical_body()

	if body == null:
		return false

	if not interaction_area.overlaps_body(body):
		return false

	return true

func is_item_in_pickup_range(item: WorldItem) -> bool:
	if item == null:
		print("[PICKUP_RANGE] item null")
		return false

	if interaction_area == null:
		print("[PICKUP_RANGE] interaction_area null")
		return false

	var body := item.get_physical_body()

	if body == null:
		print("[PICKUP_RANGE] body null item=", item.name)
		return false

	var result := interaction_area.overlaps_body(body)

	print(
		"[PICKUP_RANGE] item=", item.name,
		" body=", body.name,
		" item_pos=", item.get_world_position(),
		" worker_pos=", worker_body.global_position if worker_body != null else Vector2.ZERO,
		" result=", result
	)

	return result
	
func pickup_item(item: WorldItem) -> bool:
	if not is_item_in_pickup_range(item):
		return false
	if not can_pickup_item(item):
		return false

	var carryable := item.get_carryable_component()

	if carryable == null:
		return false

	if not item.reserve(worker_body):
		return false

	var success := carryable.pickup(
		worker_body,
		hold_point
	)

	if not success:
		item.clear_reservation(worker_body)
		return false

	if blackboard != null:
		blackboard.set_carried_item(item)

	if blackboard != null:
		blackboard.set_carried_item(item)
		blackboard.clear_assignment()
		blackboard.set_fact(&"has_assignment", false)
		blackboard.set_fact(&"has_work_target", false)

	return true


func drop_item(drop_position: Vector2) -> bool:
	if blackboard == null:
		return false

	var item := blackboard.carried_item as WorldItem

	if item == null:
		return false

	var carryable := item.get_carryable_component()

	if carryable == null:
		return false

	carryable.drop(drop_position, Vector2.ZERO)
	item.clear_reservation(worker_body)
	blackboard.carried_item = null
	blackboard.current_item = null
	blackboard.set_fact(&"has_cargo", false)
	blackboard.set_fact(&"has_item", false)
	blackboard.clear_cargo_reference()

	return true


func has_item() -> bool:
	return blackboard != null \
		and blackboard.carried_item != null \
		and is_instance_valid(blackboard.carried_item)

func get_carried_item() -> WorldItem:
	if blackboard == null:
		return null

	return blackboard.carried_item as WorldItem
