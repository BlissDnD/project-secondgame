extends Resource
class_name TerrainModifier


func apply(
	terrain_cells: Dictionary,
	generator: WorldTerrainGenerator2,
	noise: FastNoiseLite
) -> Dictionary:
	return terrain_cells
