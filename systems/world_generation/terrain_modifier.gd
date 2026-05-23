extends Resource
class_name TerrainModifier

func apply(
	terrain_cells: Dictionary,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	return terrain_cells
