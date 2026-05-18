extends RefCounted
class_name TerrainCellBuilder

static func build(config: WorldTerrainConfig, noise: FastNoiseLite) -> Dictionary:
	var terrain_cells: Dictionary = {
		&"dirt": [],
		&"stone": []
	}

	if config == null:
		push_error("TerrainCellBuilder.build: config is null.")
		return terrain_cells

	if noise == null:
		push_error("TerrainCellBuilder.build: noise is null.")
		return terrain_cells

	for x in range(config.world_width_tiles):
		var surface_y: int = config.get_surface_y_for_x(x, noise)

		for y in range(surface_y, config.world_height_tiles):
			var cell := Vector2i(x, y)
			var terrain_type: StringName = config.get_terrain_type_for_cell(y, surface_y)

			if not terrain_cells.has(terrain_type):
				terrain_cells[terrain_type] = []

			terrain_cells[terrain_type].append(cell)

	return terrain_cells
