extends Node
class_name WorldTerrainGenerator2

@export var tile_map_layer: TileMapLayer
@export var object_layer: Node2D
@export var crashed_ship_scene: PackedScene
@export var terrain_modifiers: Array[TerrainModifier] = []

@export var world_width_tiles: int = 384
@export var world_height_tiles: int = 144

@export var base_surface_y: int = 13
@export var surface_amplitude: int = 3
@export var noise_frequency: float = 0.02
@export var noise_seed: int = 12345

@export_group("Terrain Layers")
@export var dirt_depth_tiles: int = 8
@export var dirt_terrain_set: int = 0
@export var dirt_terrain_id: int = 0
@export var stone_terrain_set: int = 0
@export var stone_terrain_id: int = 1

@export_group("World Spawns")
@export var world_spawns: Array[WorldSpawnDefinition] = []

var generation_data: WorldGenerationData = WorldGenerationData.new()
var terrain_cell_types: Dictionary = {}


func _ready() -> void:
	call_deferred("generate")


func generate() -> void:
	print("=== GENERATING WORLD ===")

	if tile_map_layer == null:
		push_error("tile_map_layer is not assigned.")
		return

	if tile_map_layer.tile_set == null:
		push_error("tile_map_layer has no TileSet.")
		return

	generation_data = WorldGenerationData.new()
	terrain_cell_types.clear()

	tile_map_layer.clear()
	clear_objects()

	var terrain_cells: Dictionary = {
		&"dirt": [],
		&"stone": []
	}

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for x in range(world_width_tiles):
		var surface_y_for_x: int = get_surface_y_for_x(x, noise)

		for y in range(surface_y_for_x, world_height_tiles):
			var terrain_type: StringName = get_terrain_type_for_cell(
				x,
				y,
				surface_y_for_x
			)

			var cell: Vector2i = Vector2i(x, y)

			terrain_cells[terrain_type].append(cell)
			terrain_cell_types[cell] = terrain_type

	for modifier in terrain_modifiers:
		if modifier == null:
			continue

		terrain_cells = modifier.apply(
			terrain_cells,
			self,
			generation_data,
			noise
		)

	rebuild_terrain_cell_type_cache(terrain_cells)
	paint_terrain_cells(terrain_cells)

	spawn_world_spawns(noise)
	spawn_crashed_ship(noise)

	print("Dirt cells: ", terrain_cells[&"dirt"].size())
	print("Stone cells: ", terrain_cells[&"stone"].size())
	print("Cave floor cells: ", generation_data.cave_floor_cells.size())
	print("Objects: ", object_layer.get_child_count() if object_layer != null else 0)
	print("=== WORLD GENERATED ===")


func rebuild_terrain_cell_type_cache(terrain_cells: Dictionary) -> void:
	terrain_cell_types.clear()

	for terrain_type in terrain_cells.keys():
		for cell in terrain_cells[terrain_type]:
			terrain_cell_types[cell] = terrain_type


func get_terrain_type_for_cell(
	x: int,
	y: int,
	surface_y: int
) -> StringName:
	var depth: int = y - surface_y

	if depth < dirt_depth_tiles:
		return &"dirt"

	return &"stone"


func paint_terrain_cells(terrain_cells: Dictionary) -> void:
	tile_map_layer.set_cells_terrain_connect(
		terrain_cells[&"dirt"],
		dirt_terrain_set,
		dirt_terrain_id,
		true
	)

	tile_map_layer.set_cells_terrain_connect(
		terrain_cells[&"stone"],
		stone_terrain_set,
		stone_terrain_id,
		true
	)


func get_surface_y_for_x(x: int, noise: FastNoiseLite) -> int:
	var noise_value: float = noise.get_noise_1d(float(x))
	var surface_offset: int = roundi(noise_value * surface_amplitude)

	return base_surface_y + surface_offset


func spawn_world_spawns(noise: FastNoiseLite) -> void:
	if object_layer == null:
		push_error("object_layer is not assigned.")
		return

	for definition in world_spawns:
		if definition == null:
			continue

		if definition.scene == null:
			push_error("WorldSpawnDefinition has no scene: " + str(definition.object_id))
			continue

		match definition.spawn_location_type:
			WorldSpawnDefinition.SpawnLocationType.SURFACE:
				spawn_surface_definition(definition, noise)

			WorldSpawnDefinition.SpawnLocationType.CAVE_FLOOR:
				spawn_cave_floor_definition(definition, noise)

			WorldSpawnDefinition.SpawnLocationType.CHAMBER:
				spawn_chamber_definition(definition, noise)


func spawn_surface_definition(
	definition: WorldSpawnDefinition,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0
	var spawned_cells: Array[Vector2i] = []
	var step: int = maxi(definition.spawn_step_tiles, 1)

	for x in range(0, world_width_tiles, step):
		if definition.max_count >= 0 and spawned_count >= definition.max_count:
			return

		if randf() > definition.spawn_chance:
			continue

		var surface_y_for_x: int = get_surface_y_for_x(x, noise)
		var depth_from_surface: int = 0

		if not is_depth_allowed(definition, depth_from_surface):
			continue

		var ground_cell: Vector2i = Vector2i(
			x + definition.position_offset_tiles.x,
			surface_y_for_x + definition.position_offset_tiles.y
		)

		if is_too_close_to_spawned_cells(
			ground_cell,
			spawned_cells,
			definition.min_gap_tiles
		):
			continue

		if spawn_definition_on_cell_top(definition, ground_cell):
			spawned_cells.append(ground_cell)
			spawned_count += 1


func spawn_cave_floor_definition(
	definition: WorldSpawnDefinition,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0
	var spawned_cells: Array[Vector2i] = []

	var candidates: Array = generation_data.cave_floor_cells.duplicate()
	candidates.shuffle()

	for floor_cell in candidates:
		if definition.max_count >= 0 and spawned_count >= definition.max_count:
			return

		if randf() > definition.spawn_chance:
			continue

		if is_too_close_to_spawned_cells(
			floor_cell,
			spawned_cells,
			definition.min_gap_tiles
		):
			continue

		var surface_y_for_x: int = get_surface_y_for_x(floor_cell.x, noise)
		var depth_from_surface: int = floor_cell.y - surface_y_for_x

		if not is_depth_allowed(definition, depth_from_surface):
			continue
			
		var ground_cell: Vector2i = Vector2i(
			floor_cell.x,
			floor_cell.y + 1
		)
		var cell: Vector2i = ground_cell + definition.position_offset_tiles

		if spawn_definition_on_cell_top(definition, cell):
			spawned_cells.append(floor_cell)
			spawned_count += 1


func spawn_chamber_definition(
	definition: WorldSpawnDefinition,
	noise: FastNoiseLite
) -> void:
	var spawned_count: int = 0

	for chamber in generation_data.generated_chambers:
		if definition.max_count >= 0 and spawned_count >= definition.max_count:
			return

		if randf() > definition.spawn_chance:
			continue

		var center: Vector2i = chamber["center"]
		var chamber_radius: Vector2i = chamber["radius"]

		if chamber_radius.x < definition.minimum_chamber_radius.x:
			continue

		if chamber_radius.y < definition.minimum_chamber_radius.y:
			continue

		var surface_y_for_x: int = get_surface_y_for_x(center.x, noise)
		var depth_from_surface: int = center.y - surface_y_for_x

		if not is_depth_allowed(definition, depth_from_surface):
			continue

		var cell: Vector2i = center + definition.position_offset_tiles

		if spawn_definition_on_cell_top(definition, cell):
			spawned_count += 1


func is_depth_allowed(
	definition: WorldSpawnDefinition,
	depth_from_surface: int
) -> bool:
	return (
		depth_from_surface >= definition.min_depth_from_surface
		and depth_from_surface <= definition.max_depth_from_surface
	)


func spawn_definition_on_cell_top(
	definition: WorldSpawnDefinition,
	cell: Vector2i
) -> bool:
	if not is_spawn_cell_valid(definition, cell):
		return false

	var object := definition.scene.instantiate()
	object_layer.add_child(object)

	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)

	var local_cell_top: Vector2 = Vector2(
		cell.x * tile_size.x + tile_size.x * 0.5,
		cell.y * tile_size.y
	)

	local_cell_top.x += randf_range(
		-definition.random_x_offset_px,
		definition.random_x_offset_px
	)

	var world_pos: Vector2 = tile_map_layer.to_global(local_cell_top)

	object.global_position = world_pos

	var random_scale: float = randf_range(
		definition.scale_min,
		definition.scale_max
	)

	object.scale = Vector2.ONE * random_scale

	return true


func is_spawn_cell_valid(
	definition: WorldSpawnDefinition,
	cell: Vector2i
) -> bool:
	var ground_terrain_type: StringName = get_terrain_type_at_cell(cell)

	if definition.allowed_terrain_types.size() > 0:
		if not definition.allowed_terrain_types.has(ground_terrain_type):
			return false

	var footprint: Vector2i = definition.footprint_tiles

	for x in range(footprint.x):
		for y in range(footprint.y):
			var check_cell: Vector2i = Vector2i(
				cell.x + x,
				cell.y - 1 - y
			)

			if tile_map_layer.get_cell_source_id(check_cell) != -1:
				return false

	return true


func get_terrain_type_at_cell(cell: Vector2i) -> StringName:
	if terrain_cell_types.has(cell):
		return terrain_cell_types[cell]

	return &""


func is_too_close_to_spawned_cells(
	cell: Vector2i,
	spawned_cells: Array[Vector2i],
	min_distance_tiles: int
) -> bool:
	for spawned_cell in spawned_cells:
		var distance: float = Vector2(cell).distance_to(Vector2(spawned_cell))

		if distance < float(min_distance_tiles):
			return true

	return false


func spawn_crashed_ship(noise: FastNoiseLite) -> void:
	if crashed_ship_scene == null:
		return

	var spawn_x: int = 12
	var surface_y: int = get_surface_y_for_x(spawn_x, noise)

	var ship := crashed_ship_scene.instantiate()
	object_layer.add_child(ship)

	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)

	var local_pos: Vector2 = Vector2(
		spawn_x * tile_size.x,
		surface_y * tile_size.y
	)

	var world_pos: Vector2 = tile_map_layer.to_global(local_pos)

	ship.global_position = world_pos


func clear_objects() -> void:
	if object_layer == null:
		return

	for child in object_layer.get_children():
		child.queue_free()
