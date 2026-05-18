extends RefCounted
class_name TerrainCellIndex

var cell_to_type: Dictionary = {}


func rebuild(terrain_cells: Dictionary) -> void:
	cell_to_type.clear()

	for terrain_type in terrain_cells.keys():
		for cell in terrain_cells[terrain_type]:
			cell_to_type[cell] = terrain_type


func has_cell(cell: Vector2i) -> bool:
	return cell_to_type.has(cell)


func get_type(cell: Vector2i) -> StringName:
	if not cell_to_type.has(cell):
		return &""

	return cell_to_type[cell]


func is_type(cell: Vector2i, terrain_type: StringName) -> bool:
	return get_type(cell) == terrain_type


func get_all_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for cell in cell_to_type.keys():
		result.append(cell)

	return result


func get_cells_of_type(terrain_type: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for cell in cell_to_type.keys():
		if cell_to_type[cell] == terrain_type:
			result.append(cell)

	return result


func is_empty() -> bool:
	return cell_to_type.is_empty()
