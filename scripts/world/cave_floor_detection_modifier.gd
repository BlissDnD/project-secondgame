extends TerrainModifier
class_name CaveFloorDetectionModifier

@export var enabled: bool = true


func apply(
	terrain_cells: Dictionary,
	generator: WorldTerrainGenerator2,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	if not enabled:
		return terrain_cells

	var solid_cells: Dictionary = {}

	for terrain_type in terrain_cells.keys():
		for cell in terrain_cells[terrain_type]:
			solid_cells[cell] = true

	generation_data.cave_floor_cells.clear()

	for cell in solid_cells.keys():
		var above_cell: Vector2i = Vector2i(
			cell.x,
			cell.y - 1
		)

		if not solid_cells.has(above_cell):
			generation_data.cave_floor_cells.append(above_cell)

	print("Cave floor cells: ", generation_data.cave_floor_cells.size())

	return terrain_cells
