extends Node
class_name WorldDebugSpawnService

@export var main_crystal_scene: PackedScene
@export var crystal_node_scene: PackedScene
@export var worker_scene: PackedScene
@export var crystal_station_scene: PackedScene

@export var spawn_origin: Node2D
@export var terrain_provider: WorldTerrainGenerator2
@export var tile_map_layer: TileMapLayer
@export var object_layer: Node2D

@export var spawn_offset_tiles: int = 14
@export var object_spacing_tiles: int = 4
@export var vertical_offset_pixels: float = 0.0

var has_spawned: bool = false


func spawn_test_worker_loop_objects() -> void:
	if has_spawned:
		return

	if spawn_origin == null:
		push_warning("WorldDebugSpawnService: spawn_origin is missing.")
		return

	if terrain_provider == null:
		push_warning("WorldDebugSpawnService: terrain_provider is missing.")
		return

	if tile_map_layer == null:
		push_warning("WorldDebugSpawnService: tile_map_layer is missing.")
		return

	if object_layer == null:
		object_layer = terrain_provider.object_layer

	if object_layer == null:
		object_layer = get_tree().current_scene

	var origin_cell: Vector2i = tile_map_layer.local_to_map(
		tile_map_layer.to_local(spawn_origin.global_position)
	)

	var base_x: int = origin_cell.x + spawn_offset_tiles

	var main_x: int = base_x
	var node_x: int = base_x + object_spacing_tiles
	var station_x: int = node_x + 1
	var worker_x: int = station_x + object_spacing_tiles

	_spawn_on_surface_cell(main_crystal_scene, main_x, "MainCrystal")
	_spawn_on_surface_cell(crystal_node_scene, node_x, "CrystalNode")
	_spawn_on_surface_cell(crystal_station_scene, station_x, "CrystalNodeStation")
	_spawn_on_surface_cell(worker_scene, worker_x, "Worker")

	has_spawned = true


func _spawn_on_surface_cell(scene: PackedScene, cell_x: int, debug_name: String) -> Node:
	if scene == null:
		push_warning("WorldDebugSpawnService: missing scene for " + debug_name)
		return null

	var surface_y: int = _get_real_surface_cell_y(cell_x)
	var surface_cell := Vector2i(cell_x, surface_y)

	var instance := scene.instantiate()
	object_layer.add_child(instance)

	if instance is Node2D:
		var world_pos: Vector2 = CellPositionMapper.cell_top_to_world(
			tile_map_layer,
			surface_cell
		)

		world_pos.y += vertical_offset_pixels
		instance.global_position = world_pos

		print(
			debug_name,
			" spawned at cell=",
			surface_cell,
			" world=",
			instance.global_position
		)

	return instance


func _get_real_surface_cell_y(cell_x: int) -> int:
	if terrain_provider == null:
		return 0

	for y in range(0, terrain_provider.config.world_height_tiles):
		var cell := Vector2i(cell_x, y)

		if terrain_provider.get_terrain_type_at_cell(cell) == &"":
			continue

		var above_cell := Vector2i(cell_x, y - 1)

		if terrain_provider.get_terrain_type_at_cell(above_cell) == &"":
			return y

	push_warning("WorldDebugSpawnService: no surface found at x=" + str(cell_x))
	return 0
