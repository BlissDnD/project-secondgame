extends Node

@export var detection_area: Area2D
@export var actor: Node2D
@export var carry_socket: Node2D
@export var drop_socket: Node2D
@export var ground_search_down_tiles: int = 8

@export var placement_validator: PlacementValidator
@export var placement_preview: PlacementPreview

@export var placement_distance_tiles: int = 2
@export var placement_search_up_tiles: int = 8
@export var placement_search_down_tiles: int = 32

var terrain_layer: TileMapLayer = null

var nearby_carryables: Dictionary = {}
var current_candidate: Area2D = null
var carried: Area2D = null


func _ready() -> void:
	LoggerConsole.log("CarryManager ready")

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
		LoggerConsole.log("CarryManager warning: no terrain_layer group found.")

	if placement_validator == null:
		placement_validator = get_tree().get_first_node_in_group("placement_validator") as PlacementValidator

	if placement_preview == null:
		placement_preview = get_tree().get_first_node_in_group("placement_preview") as PlacementPreview

	if placement_validator == null:
		var root := get_tree().current_scene
		if root != null:
			placement_validator = root.find_child("PlacementValidator", true, false) as PlacementValidator

	if placement_preview == null:
		var root := get_tree().current_scene
		if root != null:
			placement_preview = root.find_child("PlacementPreview", true, false) as PlacementPreview

	if placement_validator == null:
		LoggerConsole.log("CarryManager warning: Missing PlacementValidator.")

	if placement_preview == null:
		LoggerConsole.log("CarryManager warning: Missing PlacementPreview.")

	if not detection_area.area_entered.is_connected(_on_area_entered):
		detection_area.area_entered.connect(_on_area_entered)

	if not detection_area.area_exited.is_connected(_on_area_exited):
		detection_area.area_exited.connect(_on_area_exited)

	LoggerConsole.log("CarryManager signals connected to: " + detection_area.name)


func _physics_process(_delta: float) -> void:
	if carried == null:
		current_candidate = get_closest_candidate()
	else:
		update_placement_preview()


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

	if root == null:
		return

	if root == actor:
		return

	var component: Area2D = find_carryable_component(root)

	if component == null:
		return

	if not component.can_carry():
		return

	var id: int = component.get_instance_id()

	if nearby_carryables.has(id):
		return

	nearby_carryables[id] = component


func _on_area_exited(area: Area2D) -> void:
	var root: Node = area.owner

	if root == null:
		return

	var component: Area2D = find_carryable_component(root)

	if component == null:
		return

	var id: int = component.get_instance_id()

	if nearby_carryables.has(id):
		nearby_carryables.erase(id)

	if current_candidate == component:
		current_candidate = null


func get_closest_candidate() -> Area2D:
	var closest: Area2D = null
	var closest_distance: float = INF

	for item in nearby_carryables.values():
		var component: Area2D = item as Area2D

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


func pick_up(component: Area2D) -> void:
	if carried != null:
		return

	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		return

	carried = component
	component.original_parent = carried_root.get_parent()

	_release_occupancy_if_placeable(carried_root)

	carried_root.reparent(carry_socket)
	carried_root.position = component.hold_offset

	if component.disable_body_collision_while_carried:
		set_body_collision_enabled(carried_root, false)

	component.on_picked_up(actor)

	LoggerConsole.log("Carrying: " + carried_root.name)


func release_carried() -> void:
	if carried == null:
		return

	if carried.can_insert_into_worker_socket:
		if try_insert_worker_into_socket():
			clear_placement_preview()
			return

	if carried.supports_grid_placement:
		try_place_with_grid_system(carried)
		return

	if carried.requires_ground:
		try_place_on_ground(carried)
		return

	if carried.can_drop_freely:
		drop_freely(carried)
		return

	LoggerConsole.log("This item cannot be dropped here.")


func update_placement_preview() -> void:
	if carried == null:
		clear_placement_preview()
		return

	if not carried.supports_grid_placement:
		clear_placement_preview()
		return

	if placement_validator == null:
		clear_placement_preview()
		return

	if terrain_layer == null:
		clear_placement_preview()
		return

	var definition: PlaceableDefinition = carried.placeable_definition

	if definition == null:
		clear_placement_preview()
		return

	var target_cell: Vector2i = get_grounded_placement_cell(definition)

	var cells: Array[Vector2i] = placement_validator.get_footprint_cells(
		target_cell,
		definition.footprint
	)

	var valid: bool = placement_validator.is_valid_placement(
		definition,
		target_cell,
		get_tree().current_scene
	)

	if placement_preview != null:
		placement_preview.set_preview(cells, valid)


func clear_placement_preview() -> void:
	if placement_preview != null:
		placement_preview.clear_preview()


func try_insert_worker_into_socket() -> bool:
	if carried == null:
		return false

	var worker_root: Node2D = carried.get_carried_root()

	if worker_root == null:
		return false

	for area in detection_area.get_overlapping_areas():
		if not area is WorkerSocket:
			continue

		var socket: WorkerSocket = area as WorkerSocket

		if not socket.can_accept_worker(worker_root):
			continue

		var world_parent: Node = carried.original_parent

		if world_parent == null:
			world_parent = actor.get_parent()

		worker_root.reparent(world_parent)

		set_body_collision_enabled(
			worker_root,
			carried.enable_body_collision_when_dropped
		)

		carried.on_dropped(actor)

		var inserted: bool = socket.insert_worker(worker_root)

		if not inserted:
			LoggerConsole.log("Worker socket rejected worker.")
			return false

		LoggerConsole.log("Inserted worker into socket.")

		carried = null
		return true

	return false


func try_place_with_grid_system(component: Area2D) -> void:
	if placement_validator == null:
		LoggerConsole.log("Missing PlacementValidator.")
		return

	if terrain_layer == null:
		LoggerConsole.log("Missing terrain layer.")
		return

	var definition: PlaceableDefinition = component.placeable_definition

	if definition == null:
		LoggerConsole.log("Missing PlaceableDefinition.")
		return

	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		clear_placement_preview()
		return

	var target_cell: Vector2i = get_grounded_placement_cell(definition)

	var valid: bool = placement_validator.is_valid_placement(
		definition,
		target_cell,
		get_tree().current_scene
	)

	if not valid:
		LoggerConsole.log("Invalid placement.")
		return

	var world_parent: Node = component.original_parent

	if world_parent == null:
		world_parent = actor.get_parent()

	carried_root.reparent(world_parent)

	var tile_size: Vector2 = Vector2(terrain_layer.tile_set.tile_size)
	var footprint: Vector2i = definition.footprint

	var local_place_pos: Vector2 = Vector2(
		target_cell.x * tile_size.x + tile_size.x * float(footprint.x) * 0.5,
		target_cell.y * tile_size.y + tile_size.y * float(footprint.y) * 0.5
	)

	var final_pos: Vector2 = terrain_layer.to_global(local_place_pos)
	var anchor_offset: Vector2 = Vector2.ZERO

	if component.ground_anchor != null:
		anchor_offset = (
			carried_root.global_position
			- component.ground_anchor.global_position
		)

	carried_root.global_position = final_pos + anchor_offset

	if carried_root is PlaceableObject:
		var placeable: PlaceableObject = carried_root as PlaceableObject
		placeable.definition = definition
		placeable.origin_cell = target_cell
		placeable.occupied_cells = placement_validator.get_footprint_cells(
			target_cell,
			definition.footprint
		)

		if definition.blocks_placement:
			PlacementOccupancyRegistry.occupy_cells(
				placeable.occupied_cells,
				placeable
			)

	set_body_collision_enabled(
		carried_root,
		component.enable_body_collision_when_placed
	)

	component.on_placed(actor)

	LoggerConsole.log("Placed with grid system: " + carried_root.name)

	carried = null
	clear_placement_preview()


func try_place_on_ground(component: Area2D) -> void:
	if terrain_layer == null:
		LoggerConsole.log("Cannot place: no terrain layer.")
		return

	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		return

	var start_cell: Vector2i = get_grounded_placement_cell_from_actor_x()

	var target_cell: Vector2i = find_first_empty_cell_above_ground(
		start_cell,
		ground_search_down_tiles
	)

	if target_cell == Vector2i(-999999, -999999):
		LoggerConsole.log("No valid ground found.")
		return

	var ground_cell: Vector2i = Vector2i(
		target_cell.x,
		target_cell.y + 1
	)

	if not is_valid_ground_placement(component, target_cell, ground_cell):
		LoggerConsole.log("Invalid ground placement.")
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

	var final_pos: Vector2 = terrain_layer.to_global(local_place_pos)
	var anchor_offset: Vector2 = Vector2.ZERO

	if component.ground_anchor != null:
		anchor_offset = (
			carried_root.global_position
			- component.ground_anchor.global_position
		)

	carried_root.global_position = final_pos + anchor_offset

	set_body_collision_enabled(
		carried_root,
		component.enable_body_collision_when_placed
	)

	component.on_placed(actor)

	LoggerConsole.log("Placed: " + carried_root.name)

	carried = null
	clear_placement_preview()


func drop_freely(component: Area2D) -> void:
	var carried_root: Node2D = component.get_carried_root()

	if carried_root == null:
		carried = null
		return

	var world_parent: Node = component.original_parent

	if world_parent == null:
		world_parent = actor.get_parent()

	carried_root.reparent(world_parent)
	carried_root.global_position = drop_socket.global_position

	set_body_collision_enabled(
		carried_root,
		component.enable_body_collision_when_dropped
	)

	component.on_dropped(actor)

	LoggerConsole.log("Dropped freely: " + carried_root.name)

	carried = null
	clear_placement_preview()


func get_grounded_placement_cell(definition: PlaceableDefinition) -> Vector2i:
	if terrain_layer == null:
		return Vector2i.ZERO

	var target_cell: Vector2i = get_grounded_placement_cell_from_actor_x()

	var search_start_y: int = target_cell.y - placement_search_up_tiles
	var search_end_y: int = target_cell.y + placement_search_down_tiles

	for y in range(search_start_y, search_end_y + 1):
		var origin_cell := Vector2i(target_cell.x, y)
		var cells: Array[Vector2i] = placement_validator.get_footprint_cells(
			origin_cell,
			definition.footprint
		)

		if _cells_have_ground_below(cells) and _cells_are_empty(cells):
			return origin_cell

	return target_cell


func get_grounded_placement_cell_from_actor_x() -> Vector2i:
	var facing: float = get_actor_facing_direction()

	var tile_size: Vector2 = Vector2(terrain_layer.tile_set.tile_size)

	var target_world: Vector2 = actor.global_position + Vector2(
		tile_size.x * float(placement_distance_tiles) * facing,
		0.0
	)

	var target_local: Vector2 = terrain_layer.to_local(target_world)

	return terrain_layer.local_to_map(target_local)


func get_actor_facing_direction() -> float:
	if actor.has_method("get_facing_direction"):
		return float(actor.get_facing_direction())

	var flip_container := actor.get_node_or_null("FlipContainer")

	if flip_container != null:
		if flip_container.scale.x < 0.0:
			return -1.0
		return 1.0

	if actor.scale.x < 0.0:
		return -1.0

	return 1.0


func _cells_have_ground_below(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		var below := cell + Vector2i.DOWN

		if terrain_layer.get_cell_source_id(below) == -1:
			return false

	return true


func _cells_are_empty(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if terrain_layer.get_cell_source_id(cell) != -1:
			return false

	return true


func find_first_empty_cell_above_ground(
	start_cell: Vector2i,
	max_search_down: int
) -> Vector2i:
	for offset_y in range(max_search_down + 1):
		var ground_cell: Vector2i = Vector2i(
			start_cell.x,
			start_cell.y + offset_y
		)

		var target_cell: Vector2i = Vector2i(
			ground_cell.x,
			ground_cell.y - 1
		)

		var ground_has_tile: bool = terrain_layer.get_cell_source_id(ground_cell) != -1
		var target_is_empty: bool = terrain_layer.get_cell_source_id(target_cell) == -1

		if ground_has_tile and target_is_empty:
			return target_cell

	return Vector2i(-999999, -999999)


func is_valid_ground_placement(
	component: Area2D,
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


func find_carryable_component(node: Node) -> Area2D:
	if node is Area2D:
		if node.has_method("can_carry") and node.has_method("get_carried_root"):
			return node as Area2D

	for child in node.get_children():
		var found: Area2D = find_carryable_component(child)

		if found != null:
			return found

	return null


func _release_occupancy_if_placeable(root: Node) -> void:
	if not root is PlaceableObject:
		return

	var placeable: PlaceableObject = root as PlaceableObject

	if placeable.definition == null:
		return

	if not placeable.definition.blocks_placement:
		return

	PlacementOccupancyRegistry.release_cells(
		placeable.occupied_cells,
		placeable
	)
