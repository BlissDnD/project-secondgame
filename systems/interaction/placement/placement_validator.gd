extends Node
class_name PlacementValidator

@export var terrain_tilemap: Node
@export var cell_size: Vector2 = Vector2(32, 32)


func get_footprint_cells(origin_cell: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for y in range(footprint.y):
		for x in range(footprint.x):
			cells.append(origin_cell + Vector2i(x, y))

	return cells


func is_valid_placement(
	definition: PlaceableDefinition,
	origin_cell: Vector2i,
	world_root: Node
) -> bool:
	var cells := get_footprint_cells(origin_cell, definition.footprint)

	if not PlacementOccupancyRegistry.are_cells_free(cells):
		return false

	if not _validate_placement_mode(definition, origin_cell, cells):
		return false

	if not _validate_required_node(definition, origin_cell, world_root):
		return false

	return true


func _validate_placement_mode(
	definition: PlaceableDefinition,
	origin_cell: Vector2i,
	cells: Array[Vector2i]
) -> bool:
	match definition.placement_mode:
		PlacementTypes.PlacementMode.GROUNDED:
			return _has_ground_below(cells)

		PlacementTypes.PlacementMode.GROUNDED_ALL:
			return _has_ground_below(cells)

		PlacementTypes.PlacementMode.GROUNDED_DIRT:
			return _has_ground_below(cells) and _ground_matches_terrain(cells, &"dirt")

		PlacementTypes.PlacementMode.WALL:
			return _has_wall_support(cells)

		PlacementTypes.PlacementMode.CEILING:
			return _has_ceiling_support(cells)

		PlacementTypes.PlacementMode.BACKGROUND:
			return true

	return false


func _validate_required_node(
	definition: PlaceableDefinition,
	origin_cell: Vector2i,
	world_root: Node
) -> bool:
	if definition.required_node_group == "":
		return true

	var radius := definition.required_node_radius_tiles
	if radius <= 0:
		return false

	var origin_world := Vector2(origin_cell) * cell_size

	for node in world_root.get_tree().get_nodes_in_group(definition.required_node_group):
		if not node is Node2D:
			continue

		var node_cell := world_to_cell(node.global_position)
		var distance: int = abs(node_cell.x - origin_cell.x) + abs(node_cell.y - origin_cell.y)

		if distance <= radius:
			return true

	return false


func _has_ground_below(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		var below := cell + Vector2i.DOWN
		if not _has_terrain_at_cell(below):
			return false

	return true


func _ground_matches_terrain(cells: Array[Vector2i], required_type: StringName) -> bool:
	for cell in cells:
		var below := cell + Vector2i.DOWN
		var terrain_type := _get_terrain_type_at_cell(below)

		if terrain_type != required_type:
			return false

	return true


func _has_wall_support(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if _has_terrain_at_cell(cell + Vector2i.LEFT):
			return true
		if _has_terrain_at_cell(cell + Vector2i.RIGHT):
			return true

	return false


func _has_ceiling_support(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if not _has_terrain_at_cell(cell + Vector2i.UP):
			return false

	return true


func _has_terrain_at_cell(cell: Vector2i) -> bool:
	if terrain_tilemap == null:
		return false

	if terrain_tilemap.has_method("get_cell_source_id"):
		return terrain_tilemap.get_cell_source_id(cell) != -1

	if terrain_tilemap.has_method("get_cell_tile_data"):
		return terrain_tilemap.get_cell_tile_data(cell) != null

	return false


func _get_terrain_type_at_cell(cell: Vector2i) -> StringName:
	if terrain_tilemap == null:
		return &""

	if terrain_tilemap.has_method("get_cell_tile_data"):
		var data = terrain_tilemap.get_cell_tile_data(cell)
		if data != null:
			var custom_type = data.get_custom_data("terrain_type")
			if custom_type != null:
				return StringName(str(custom_type))

	return &""


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size.x),
		floori(world_position.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size.x, cell.y * cell_size.y)
