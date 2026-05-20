extends Node
class_name WorldTerrainGenerator2

@export var tile_map_layer: TileMapLayer
@export var object_layer: Node2D
@export var crashed_ship_scene: PackedScene
@export var terrain_modifiers: Array[TerrainModifier] = []

@export var config: WorldTerrainConfig

@export_group("World Spawns")
@export var world_spawns: Array[WorldSpawnDefinition] = []

@export_group("NPC Spawns")
@export var npc_definitions: Array[NPCDefinition] = []

var generation_data: WorldGenerationData = WorldGenerationData.new()
var terrain_index: TerrainCellIndex = TerrainCellIndex.new()


func _ready() -> void:
	call_deferred("generate")


func generate() -> void:
	print("=== GENERATING WORLD ===")

	if not _is_valid_setup():
		return

	generation_data = WorldGenerationData.new()
	terrain_index = TerrainCellIndex.new()

	tile_map_layer.clear()
	clear_objects()

	var noise: FastNoiseLite = config.create_noise()

	var terrain_cells: Dictionary = TerrainCellBuilder.build(
		config,
		noise
	)

	terrain_cells = TerrainModifierPipeline.apply(
		terrain_cells,
		terrain_modifiers,
		config,
		generation_data,
		noise
	)

	terrain_index.rebuild(terrain_cells)

	TerrainPainter.paint(
		tile_map_layer,
		config,
		terrain_cells
	)

	WorldSpawnController.spawn_all(
		world_spawns,
		object_layer,
		tile_map_layer,
		config,
		generation_data,
		terrain_index,
		noise
	)

	spawn_npcs(noise)
	spawn_crashed_ship(noise)
	
	_spawn_debug_worker_loop_objects()

	print("Dirt cells: ", terrain_cells.get(&"dirt", []).size())
	print("Stone cells: ", terrain_cells.get(&"stone", []).size())
	print("Cave floor cells: ", generation_data.cave_floor_cells.size())
	print("Objects: ", object_layer.get_child_count())
	print("=== WORLD GENERATED ===")


func _is_valid_setup() -> bool:
	if config == null:
		push_error("WorldTerrainGenerator2: config is not assigned.")
		return false

	if tile_map_layer == null:
		push_error("WorldTerrainGenerator2: tile_map_layer is not assigned.")
		return false

	if tile_map_layer.tile_set == null:
		push_error("WorldTerrainGenerator2: tile_map_layer has no TileSet.")
		return false

	if object_layer == null:
		push_error("WorldTerrainGenerator2: object_layer is not assigned.")
		return false

	return true


func spawn_npcs(noise: FastNoiseLite) -> void:
	for definition in npc_definitions:
		if definition == null:
			continue

		if definition.npc_scene == null:
			push_error("NPCDefinition has no npc_scene: " + str(definition.npc_id))
			continue

		match definition.spawn_mode:
			NPCDefinition.SpawnMode.SURFACE_INTERVAL:
				spawn_surface_npc_definition(definition, noise)

			_:
				pass


func spawn_surface_npc_definition(
	definition: NPCDefinition,
	noise: FastNoiseLite
) -> void:
	print("Trying to spawn NPC: ", definition.npc_id)

	var spawned_count: int = 0
	var min_x: int = 40
	var max_x: int = mini(120, config.world_width_tiles - 1)

	if max_x <= min_x:
		push_warning("NPC spawn failed: world is too narrow.")
		return

	var candidate_x_positions: Array[int] = []

	for x in range(min_x, max_x):
		candidate_x_positions.append(x)

	candidate_x_positions.shuffle()

	for x in candidate_x_positions:
		if definition.max_count >= 0 and spawned_count >= definition.max_count:
			print("NPC spawn complete: ", definition.npc_id)
			return

		if randf() > definition.spawn_chance:
			continue

		var surface_y: int = config.get_surface_y_for_x(x, noise)
		var ground_cell := Vector2i(x, surface_y)

		if not is_npc_surface_cell_valid(ground_cell):
			continue

		if spawn_npc_on_cell_top(definition, ground_cell):
			spawned_count += 1
			print("NPC spawned successfully: ", definition.npc_id, " at cell ", ground_cell)
			return

	print("NPC spawn failed: no valid surface cell found for ", definition.npc_id)


func is_npc_surface_cell_valid(cell: Vector2i) -> bool:
	if terrain_index.get_type(cell) == &"":
		return false

	var above_cell := Vector2i(cell.x, cell.y - 1)

	if terrain_index.get_type(above_cell) != &"":
		return false

	return true


func spawn_npc_on_cell_top(
	definition: NPCDefinition,
	cell: Vector2i
) -> bool:
	var npc := definition.npc_scene.instantiate() as Node2D

	if npc == null:
		print("NPC spawn failed: npc_scene root is not Node2D")
		return false

	object_layer.add_child(npc)

	var world_pos: Vector2 = CellPositionMapper.cell_top_to_world(
		tile_map_layer,
		cell
	)

	world_pos.y -= 8.0
	npc.global_position = world_pos

	if npc.has_method("setup"):
		npc.setup(definition, world_pos)

	print("Spawned NPC: ", definition.npc_id, " at world position ", world_pos)

	return true


func spawn_crashed_ship(noise: FastNoiseLite) -> void:
	if crashed_ship_scene == null:
		return

	var spawn_x: int = 12
	var surface_y: int = config.get_surface_y_for_x(spawn_x, noise)
	var cell := Vector2i(spawn_x, surface_y)

	var ship := crashed_ship_scene.instantiate() as Node2D

	if ship == null:
		push_warning("Crashed ship scene root is not Node2D.")
		return

	object_layer.add_child(ship)

	ship.global_position = CellPositionMapper.cell_top_to_world(
		tile_map_layer,
		cell
	)


func get_terrain_type_at_cell(cell: Vector2i) -> StringName:
	return terrain_index.get_type(cell)


func clear_objects() -> void:
	if object_layer == null:
		return

	for child in object_layer.get_children():
		child.queue_free()
		
func _spawn_debug_worker_loop_objects() -> void:
	var spawn_service := get_node_or_null("WorldDebugSpawnService")

	if spawn_service == null:
		push_warning("WorldDebugSpawnService not found.")
		return

	spawn_service.spawn_test_worker_loop_objects()
