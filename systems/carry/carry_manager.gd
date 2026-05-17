extends Node

@export var detection_area: Area2D
@export var actor: Node2D
@export var carry_socket: Node2D

var nearby_carryables: Dictionary = {}
var current_candidate: Node = null
var carried: Node = null


func _ready() -> void:
	if detection_area == null:
		push_error("CarryManager: detection_area is not assigned.")
		return

	if actor == null:
		push_error("CarryManager: actor is not assigned.")
		return

	if carry_socket == null:
		push_error("CarryManager: carry_socket is not assigned.")
		return

	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	if carried == null:
		current_candidate = get_closest_candidate()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pickup_drop"):
		if carried != null:
			drop_carried()
			return

		if current_candidate != null:
			pick_up(current_candidate)
		else:
			LoggerConsole.log("No carry target.")


func _on_area_entered(area: Area2D) -> void:
	var root: Node = area.owner

	if root == null:
		return

	if root == actor:
		return

	var component: Node = find_carryable_component(root)

	if component == null:
		return

	if not component.can_carry():
		return

	var id: int = component.get_instance_id()

	if nearby_carryables.has(id):
		return

	nearby_carryables[id] = component
	LoggerConsole.log("Added carryable: " + root.name)


func _on_area_exited(area: Area2D) -> void:
	var root: Node = area.owner

	if root == null:
		return

	var component: Node = find_carryable_component(root)

	if component == null:
		return

	var id: int = component.get_instance_id()

	if nearby_carryables.has(id):
		nearby_carryables.erase(id)

	if current_candidate == component:
		current_candidate = null


func get_closest_candidate() -> Node:
	var closest: Node = null
	var closest_distance: float = INF

	for item in nearby_carryables.values():
		var component: Node = item as Node

		if component == null:
			continue

		if not is_instance_valid(component):
			continue

		if not component.can_carry():
			continue

		var carried_root: Node2D = component.get_carried_root()

		if carried_root == null:
			continue

		var distance: float = actor.global_position.distance_to(
			carried_root.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest = component

	return closest


func pick_up(component: Node) -> void:
	if carried != null:
		return

	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		return

	carried = component
	component.original_parent = carried_root.get_parent()

	carried_root.reparent(carry_socket)
	carried_root.position = component.hold_offset

	set_collision_enabled(carried_root, false)

	component.on_picked_up(actor)
	LoggerConsole.log("Carrying: " + carried_root.name)


func drop_carried() -> void:
	if carried == null:
		return

	var component: Node = carried
	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		return

	var world_parent: Node = component.original_parent

	if world_parent == null:
		world_parent = actor.get_parent()

	var drop_global_position: Vector2 = actor.global_position + component.drop_offset

	carried_root.reparent(world_parent)
	carried_root.global_position = drop_global_position

	set_collision_enabled(carried_root, true)

	component.on_dropped(actor)
	LoggerConsole.log("Dropped: " + carried_root.name)

	carried = null


func set_collision_enabled(root: Node, enabled: bool) -> void:
	for child in root.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled

		if child is CollisionPolygon2D:
			child.disabled = not enabled

		set_collision_enabled(child, enabled)


func find_carryable_component(node: Node) -> Node:
	if node.has_method("can_carry") and node.has_method("get_carried_root"):
		return node

	for child in node.get_children():
		var found: Node = find_carryable_component(child)

		if found != null:
			return found

	return null
