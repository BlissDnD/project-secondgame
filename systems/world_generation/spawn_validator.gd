extends RefCounted
class_name SpawnValidator

static func is_depth_allowed(
	cell: Vector2i,
	min_depth_from_surface: int,
	max_depth_from_surface: int,
	surface_y: int
) -> bool:
	var depth: int = cell.y - surface_y

	if min_depth_from_surface >= 0 and depth < min_depth_from_surface:
		return false

	if max_depth_from_surface >= 0 and depth > max_depth_from_surface:
		return false

	return true


static func is_far_enough_from_cells(
	cell: Vector2i,
	used_cells: Array[Vector2i],
	min_distance: int
) -> bool:
	if min_distance <= 0:
		return true

	for used_cell in used_cells:
		if cell.distance_to(used_cell) < float(min_distance):
			return false

	return true


static func has_required_footprint(
	cell: Vector2i,
	terrain_index: TerrainCellIndex,
	required_ground_width: int
) -> bool:
	if terrain_index == null:
		return false

	if required_ground_width <= 1:
		return terrain_index.has_cell(cell)

	var half_width: int = required_ground_width / 2

	for offset_x in range(-half_width, half_width + 1):
		var check_cell := Vector2i(cell.x + offset_x, cell.y)

		if not terrain_index.has_cell(check_cell):
			return false

	return true


static func has_empty_space_above(
	cell: Vector2i,
	terrain_index: TerrainCellIndex,
	required_height: int
) -> bool:
	if terrain_index == null:
		return false

	if required_height <= 0:
		return true

	for offset_y in range(1, required_height + 1):
		var check_cell := Vector2i(cell.x, cell.y - offset_y)

		if terrain_index.has_cell(check_cell):
			return false

	return true


static func is_valid_surface_spawn_cell(
	cell: Vector2i,
	terrain_index: TerrainCellIndex,
	surface_y: int,
	min_depth_from_surface: int,
	max_depth_from_surface: int,
	required_ground_width: int,
	required_empty_height: int,
	used_cells: Array[Vector2i],
	min_distance_between_spawns: int
) -> bool:
	if terrain_index == null:
		return false

	if not terrain_index.has_cell(cell):
		return false

	if not is_depth_allowed(
		cell,
		min_depth_from_surface,
		max_depth_from_surface,
		surface_y
	):
		return false

	if not has_required_footprint(
		cell,
		terrain_index,
		required_ground_width
	):
		return false

	if not has_empty_space_above(
		cell,
		terrain_index,
		required_empty_height
	):
		return false

	if not is_far_enough_from_cells(
		cell,
		used_cells,
		min_distance_between_spawns
	):
		return false

	return true
