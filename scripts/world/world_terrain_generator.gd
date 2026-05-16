extends Node
class_name WorldTerrainGenerator

@export var tile_map_layer: TileMapLayer
@export var config: TerrainGenerationConfig

@export var override_surface_y: int = 12


func _ready() -> void:
	generate()


func generate() -> void:
	print("=== GENERATING NEW WORLD ===")

	if tile_map_layer == null:
		push_error("WorldTerrainGenerator: tile_map_layer is not assigned.")
		return

	if config == null:
		push_error("WorldTerrainGenerator: config is not assigned.")
		return

	print("Config path: ", config.resource_path)
	print("Surface Y: ", override_surface_y)
	print("World width: ", config.get_world_width_tiles())
	print("World height: ", config.get_world_height_tiles())

	tile_map_layer.clear()

	var dirt_cells: Array[Vector2i] = []

	var world_width := config.get_world_width_tiles()
	var world_height := config.get_world_height_tiles()

	for x in range(world_width):
		for y in range(override_surface_y, world_height):
			dirt_cells.append(Vector2i(x, y))

	print("Dirt cells: ", dirt_cells.size())

	tile_map_layer.set_cells_terrain_connect(
		dirt_cells,
		config.terrain_set_id,
		config.dirt_terrain_id,
		true
	)

	print("=== WORLD GENERATED ===")
