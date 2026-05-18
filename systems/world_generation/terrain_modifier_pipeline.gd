extends RefCounted
class_name TerrainModifierPipeline

static func apply(
	terrain_cells: Dictionary,
	modifiers: Array[TerrainModifier],
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	var result: Dictionary = terrain_cells

	for modifier in modifiers:
		if modifier == null:
			continue

		result = modifier.apply(
			result,
			config,
			generation_data,
			noise
		)

	return result
