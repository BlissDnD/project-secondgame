extends RefCounted
class_name CellPositionMapper

static func cell_top_to_world(tile_map_layer: TileMapLayer, cell: Vector2i) -> Vector2:
	if tile_map_layer == null:
		push_error("CellPositionMapper.cell_top_to_world: tile_map_layer is null.")
		return Vector2.ZERO

	if tile_map_layer.tile_set == null:
		push_error("CellPositionMapper.cell_top_to_world: tile_map_layer has no TileSet.")
		return Vector2.ZERO

	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)

	var local_position := Vector2(
		float(cell.x) * tile_size.x + tile_size.x * 0.5,
		float(cell.y) * tile_size.y
	)

	return tile_map_layer.to_global(local_position)


static func cell_center_to_world(tile_map_layer: TileMapLayer, cell: Vector2i) -> Vector2:
	if tile_map_layer == null:
		push_error("CellPositionMapper.cell_center_to_world: tile_map_layer is null.")
		return Vector2.ZERO

	if tile_map_layer.tile_set == null:
		push_error("CellPositionMapper.cell_center_to_world: tile_map_layer has no TileSet.")
		return Vector2.ZERO

	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)

	var local_position := Vector2(
		float(cell.x) * tile_size.x + tile_size.x * 0.5,
		float(cell.y) * tile_size.y + tile_size.y * 0.5
	)

	return tile_map_layer.to_global(local_position)


static func cell_bottom_to_world(tile_map_layer: TileMapLayer, cell: Vector2i) -> Vector2:
	if tile_map_layer == null:
		push_error("CellPositionMapper.cell_bottom_to_world: tile_map_layer is null.")
		return Vector2.ZERO

	if tile_map_layer.tile_set == null:
		push_error("CellPositionMapper.cell_bottom_to_world: tile_map_layer has no TileSet.")
		return Vector2.ZERO

	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)

	var local_position := Vector2(
		float(cell.x) * tile_size.x + tile_size.x * 0.5,
		float(cell.y) * tile_size.y + tile_size.y
	)

	return tile_map_layer.to_global(local_position)
