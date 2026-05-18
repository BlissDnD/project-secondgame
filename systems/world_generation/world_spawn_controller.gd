extends RefCounted
class_name WorldSpawnController

static func spawn_all(
	world_spawns: Array[WorldSpawnDefinition],
	object_layer: Node2D,
	tile_map_layer: TileMapLayer,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	terrain_index: TerrainCellIndex,
	noise: FastNoiseLite
) -> void:
	if object_layer == null:
		push_error("WorldSpawnController.spawn_all: object_layer is null.")
		return

	if tile_map_layer == null:
		push_error("WorldSpawnController.spawn_all: tile_map_layer is null.")
		return

	if config == null:
		push_error("WorldSpawnController.spawn_all: config is null.")
		return

	if terrain_index == null:
		push_error("WorldSpawnController.spawn_all: terrain_index is null.")
		return

	for definition in world_spawns:
		if definition == null:
			continue

		if definition.scene == null:
			push_error("WorldSpawnDefinition has no scene: " + str(definition.object_id))
			continue

		match definition.spawn_location_type:
			WorldSpawnDefinition.SpawnLocationType.SURFACE:
				_spawn_surface_definition(
					definition,
					object_layer,
					tile_map_layer,
					config,
					terrain_index,
					noise
				)

			WorldSpawnDefinition.SpawnLocationType.CAVE_FLOOR:
				_spawn_cave_floor_definition(
					definition,
					object_layer,
					tile_map_layer,
					config,
					generation_data,
					terrain_index,
					noise
				)

			WorldSpawnDefinition.SpawnLocationType.CHAMBER:
				_spawn_chamber_definition(
					definition,
					object_layer,
					tile_map_layer,
					config,
					generation_data,
					terrain_index,
					noise
				)


static func _spawn_surface_definition(
	definition: WorldSpawnDefinition,
	object_layer: Node2D,
	tile_map_layer: TileMapLayer,
	config: WorldTerrainConfig,
	terrain_index: TerrainCellIndex,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0
	var spawned_cells: Array[Vector2i] = []
	var step: int = maxi(definition.spawn_step_tiles, 1)

	for x in range(0, config.world_width_tiles, step):
		if _is_spawn_limit_reached(definition, spawned_count):
			return

		if randf() > definition.spawn_chance:
			continue

		var surface_y: int = config.get_surface_y_for_x(x, noise)

		var ground_cell := Vector2i(
			x + definition.position_offset_tiles.x,
			surface_y + definition.position_offset_tiles.y
		)

		if not _is_world_spawn_cell_valid(
			definition,
			ground_cell,
			surface_y,
			terrain_index,
			spawned_cells
		):
			continue

		if _spawn_definition_on_cell_top(
			definition,
			ground_cell,
			object_layer,
			tile_map_layer
		):
			spawned_cells.append(ground_cell)
			spawned_count += 1


static func _spawn_cave_floor_definition(
	definition: WorldSpawnDefinition,
	object_layer: Node2D,
	tile_map_layer: TileMapLayer,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	terrain_index: TerrainCellIndex,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0
	var spawned_cells: Array[Vector2i] = []

	var candidates: Array = generation_data.cave_floor_cells.duplicate()
	candidates.shuffle()

	for floor_cell in candidates:
		if _is_spawn_limit_reached(definition, spawned_count):
			return

		if randf() > definition.spawn_chance:
			continue

		var surface_y: int = config.get_surface_y_for_x(floor_cell.x, noise)

		var ground_cell := Vector2i(
			floor_cell.x,
			floor_cell.y + 1
		)

		var spawn_cell: Vector2i = ground_cell + definition.position_offset_tiles

		if not _is_world_spawn_cell_valid(
			definition,
			spawn_cell,
			surface_y,
			terrain_index,
			spawned_cells
		):
			continue

		if _spawn_definition_on_cell_top(
			definition,
			spawn_cell,
			object_layer,
			tile_map_layer
		):
			spawned_cells.append(floor_cell)
			spawned_count += 1


static func _spawn_chamber_definition(
	definition: WorldSpawnDefinition,
	object_layer: Node2D,
	tile_map_layer: TileMapLayer,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	terrain_index: TerrainCellIndex,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0

	for chamber in generation_data.generated_chambers:
		if _is_spawn_limit_reached(definition, spawned_count):
			return

		if randf() > definition.spawn_chance:
			continue

		var center: Vector2i = chamber["center"]
		var chamber_radius: Vector2i = chamber["radius"]

		if chamber_radius.x < definition.minimum_chamber_radius.x:
			continue

		if chamber_radius.y < definition.minimum_chamber_radius.y:
			continue

		var surface_y: int = config.get_surface_y_for_x(center.x, noise)
		var spawn_cell: Vector2i = center + definition.position_offset_tiles

		if not _is_world_spawn_cell_valid(
			definition,
			spawn_cell,
			surface_y,
			terrain_index,
			[]
		):
			continue

		if _spawn_definition_on_cell_top(
			definition,
			spawn_cell,
			object_layer,
			tile_map_layer
		):
			spawned_count += 1


static func _is_world_spawn_cell_valid(
	definition: WorldSpawnDefinition,
	cell: Vector2i,
	surface_y: int,
	terrain_index: TerrainCellIndex,
	spawned_cells: Array[Vector2i]
) -> bool:
	if terrain_index == null:
		return false

	var ground_terrain_type: StringName = terrain_index.get_type(cell)

	if ground_terrain_type == &"":
		return false

	if definition.allowed_terrain_types.size() > 0:
		if not definition.allowed_terrain_types.has(ground_terrain_type):
			return false

	if not SpawnValidator.is_depth_allowed(
		cell,
		definition.min_depth_from_surface,
		definition.max_depth_from_surface,
		surface_y
	):
		return false

	if not SpawnValidator.is_far_enough_from_cells(
		cell,
		spawned_cells,
		definition.min_gap_tiles
	):
		return false

	if not _has_empty_footprint_above(definition, cell, terrain_index):
		return false

	return true


static func _has_empty_footprint_above(
	definition: WorldSpawnDefinition,
	cell: Vector2i,
	terrain_index: TerrainCellIndex
) -> bool:
	var footprint: Vector2i = definition.footprint_tiles

	for x in range(footprint.x):
		for y in range(footprint.y):
			var check_cell := Vector2i(
				cell.x + x,
				cell.y - 1 - y
			)

			if terrain_index.has_cell(check_cell):
				return false

	return true


static func _spawn_definition_on_cell_top(
	definition: WorldSpawnDefinition,
	cell: Vector2i,
	object_layer: Node2D,
	tile_map_layer: TileMapLayer
) -> bool:
	if definition.scene == null:
		return false

	var object: Node2D = definition.scene.instantiate() as Node2D

	if object == null:
		push_warning("WorldSpawnDefinition scene root is not Node2D: " + str(definition.object_id))
		return false

	object_layer.add_child(object)

	var world_position: Vector2 = CellPositionMapper.cell_top_to_world(
		tile_map_layer,
		cell
	)

	world_position.x += randf_range(
		-definition.random_x_offset_px,
		definition.random_x_offset_px
	)

	object.global_position = world_position

	var random_scale: float = randf_range(
		definition.scale_min,
		definition.scale_max
	)

	object.scale = Vector2.ONE * random_scale

	return true


static func _is_spawn_limit_reached(
	definition: WorldSpawnDefinition,
	spawned_count: int
) -> bool:
	return definition.max_count >= 0 and spawned_count >= definition.max_count
