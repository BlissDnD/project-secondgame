extends RefCounted
class_name TerrainPainter

static func paint(
	tile_map_layer: TileMapLayer,
	config: WorldTerrainConfig,
	terrain_cells: Dictionary
) -> void:
	if tile_map_layer == null:
		push_error("TerrainPainter.paint: tile_map_layer is null.")
		return

	if config == null:
		push_error("TerrainPainter.paint: config is null.")
		return

	tile_map_layer.clear()

	var dirt_cells: Array[Vector2i] = _get_typed_cells(terrain_cells, &"dirt")
	var stone_cells: Array[Vector2i] = _get_typed_cells(terrain_cells, &"stone")

	if not dirt_cells.is_empty():
		tile_map_layer.set_cells_terrain_connect(
			dirt_cells,
			config.dirt_terrain_set,
			config.dirt_terrain_id
		)

	if not stone_cells.is_empty():
		tile_map_layer.set_cells_terrain_connect(
			stone_cells,
			config.stone_terrain_set,
			config.stone_terrain_id
		)


static func _get_typed_cells(
	terrain_cells: Dictionary,
	terrain_type: StringName
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not terrain_cells.has(terrain_type):
		return result

	for cell in terrain_cells[terrain_type]:
		result.append(cell)

	return result
