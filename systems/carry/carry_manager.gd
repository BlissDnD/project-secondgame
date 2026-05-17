extends Node

@export var detection_area: Area2D
@export var actor: Node2D
@export var carry_socket: Node2D
@export var drop_socket: Node2D

var terrain_layer: TileMapLayer = null

var nearby_carryables: Dictionary = {}
var current_candidate: Node = null
var carried: Node = null


func _ready() -> void:
	print("CARRY MANAGER READY")
	if detection_area == null:
		push_error("CarryManager: detection_area is not assigned.")
		return

	if actor == null:
		push_error("CarryManager: actor is not assigned.")
		return

	if carry_socket == null:
		push_error("CarryManager: carry_socket is not assigned.")
		return

	if drop_socket == null:
		push_error("CarryManager: drop_socket is not assigned.")
		return
	
	terrain_layer = get_tree().get_first_node_in_group("terrain_layer") as TileMapLayer

	if terrain_layer == null:
		push_error("CarryManager: terrain_layer is not assigned.")
		return

	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)
	LoggerConsole.log("CarryManager ready")
	LoggerConsole.log("DetectionArea: " + str(detection_area))
	LoggerConsole.log("Actor: " + str(actor))
	LoggerConsole.log("CarrySocket: " + str(carry_socket))
	LoggerConsole.log("DropSocket: " + str(drop_socket))

	detection_area.area_entered.connect(_on_area_entered)
	detection_area.area_exited.connect(_on_area_exited)

	LoggerConsole.log("CarryManager signals connected")


func _physics_process(_delta: float) -> void:
	if carried == null:
		current_candidate = get_closest_candidate()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pickup_drop"):
		if carried != null:
			release_carried()
			return

		if current_candidate != null:
			pick_up(current_candidate)
		else:
			LoggerConsole.log("No carry target.")


func _on_area_entered(area: Area2D) -> void:
	
	var root: Node = area.owner
	LoggerConsole.log("CARRY AREA ENTERED: " + area.name)
	if root == null:
		return

	if root == actor:
		LoggerConsole.log("Carry entered area has no owner.")
		return

	var component: Node = find_carryable_component(root)

	if component == null:
		LoggerConsole.log("No CarryableComponent on: " + root.name)
		return

	if not component.can_carry():
		return

	var id: int = component.get_instance_id()

	if nearby_carryables.has(id):
		LoggerConsole.log("Found CarryableComponent on: " + root.name)
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

	set_body_collision_enabled(carried_root, false)

	component.on_picked_up(actor)
	LoggerConsole.log("Carrying: " + carried_root.name)


func release_carried() -> void:
	if carried == null:
		return

	if carried.requires_ground:
		try_place_on_ground(carried)
	else:
		drop_freely(carried)


func try_place_on_ground(component: Node) -> void:
	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		return

	var drop_local: Vector2 = terrain_layer.to_local(drop_socket.global_position)
	var target_cell: Vector2i = terrain_layer.local_to_map(drop_local)

	var ground_cell: Vector2i = Vector2i(
		target_cell.x,
		target_cell.y + 1
	)

	if not is_valid_ground_placement(component, target_cell, ground_cell):
		LoggerConsole.log("Cannot place here.")
		return

	var world_parent: Node = component.original_parent

	if world_parent == null:
		world_parent = actor.get_parent()

	carried_root.reparent(world_parent)

	var tile_size: Vector2 = Vector2(terrain_layer.tile_set.tile_size)

	var local_place_pos: Vector2 = Vector2(
		target_cell.x * tile_size.x + tile_size.x * 0.5,
		ground_cell.y * tile_size.y
	)

	carried_root.global_position = terrain_layer.to_global(local_place_pos)

	set_body_collision_enabled(carried_root, false)

	component.on_placed(actor)
	LoggerConsole.log("Placed: " + carried_root.name)

	carried = null


func drop_freely(component: Node) -> void:
	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		return

	var world_parent: Node = component.original_parent

	if world_parent == null:
		world_parent = actor.get_parent()

	carried_root.reparent(world_parent)
	carried_root.global_position = drop_socket.global_position

	set_body_collision_enabled(carried_root, true)

	component.on_dropped(actor)
	LoggerConsole.log("Dropped freely: " + carried_root.name)

	carried = null


func is_valid_ground_placement(
	component: Node,
	target_cell: Vector2i,
	ground_cell: Vector2i
) -> bool:
	var footprint: Vector2i = component.footprint_tiles

	for x in range(footprint.x):
		var check_ground_cell: Vector2i = Vector2i(
			ground_cell.x + x,
			ground_cell.y
		)

		var check_space_cell: Vector2i = Vector2i(
			target_cell.x + x,
			target_cell.y
		)

		if terrain_layer.get_cell_source_id(check_ground_cell) == -1:
			return false

		if terrain_layer.get_cell_source_id(check_space_cell) != -1:
			return false

	return true


func set_body_collision_enabled(root: Node, enabled: bool) -> void:
	for child in root.get_children():
		if child.name == "BodyCollider":
			for body_child in child.get_children():
				if body_child is CollisionShape2D:
					body_child.disabled = not enabled

				if body_child is CollisionPolygon2D:
					body_child.disabled = not enabled

		set_body_collision_enabled(child, enabled)


func find_carryable_component(node: Node) -> Node:
	if node.has_method("can_carry") and node.has_method("get_carried_root"):
		return node

	for child in node.get_children():
		var found: Node = find_carryable_component(child)

		if found != null:
			return found

	return null
