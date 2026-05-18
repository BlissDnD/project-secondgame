extends TerrainModifier
class_name CaveFloorDetectionModifier

@export var enabled: bool = true


func apply(
	terrain_cells: Dictionary,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	if not enabled:
		return terrain_cells

	if generation_data == null:
		push_error("CaveFloorDetectionModifier.apply: generation_data is null.")
		return terrain_cells

	generation_data.cave_floor_cells.clear()

	var solid_cells: Dictionary = {}

	for terrain_type in terrain_cells.keys():
		for cell in terrain_cells[terrain_type]:
			solid_cells[cell] = true

	for cell in solid_cells.keys():
		if not _is_cave_floor_cell(cell, solid_cells):
			continue

		generation_data.cave_floor_cells.append(cell)

	return terrain_cells


func _is_cave_floor_cell(
	cell: Vector2i,
	solid_cells: Dictionary
) -> bool:
	var above_cell := Vector2i(cell.x, cell.y - 1)

	if solid_cells.has(above_cell):
		return false

	return true
