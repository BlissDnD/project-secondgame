extends TerrainModifier
class_name GapTerrainModifier

@export var gap_start_x: int = 150
@export var gap_width: int = 20
@export var gap_depth: int = 40


func apply(
	terrain_cells: Dictionary,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	if config == null:
		push_error("GapTerrainModifier.apply: config is null.")
		return terrain_cells

	if noise == null:
		push_error("GapTerrainModifier.apply: noise is null.")
		return terrain_cells

	print("Gap modifier values: start=", gap_start_x, " width=", gap_width, " depth=", gap_depth)

	for x in range(gap_start_x, gap_start_x + gap_width):
		if x < 0 or x >= config.world_width_tiles:
			continue

		var surface_y: int = config.get_surface_y_for_x(x, noise)
		var max_y: int = mini(surface_y + gap_depth, config.world_height_tiles)

		for y in range(surface_y, max_y):
			var cell := Vector2i(x, y)
			_remove_cell_from_terrain(terrain_cells, cell)

	return terrain_cells


func _remove_cell_from_terrain(
	terrain_cells: Dictionary,
	cell: Vector2i
) -> void:
	for terrain_type in terrain_cells.keys():
		var cells: Array = terrain_cells[terrain_type]
		var index: int = cells.find(cell)

		if index != -1:
			cells.remove_at(index)
			return
