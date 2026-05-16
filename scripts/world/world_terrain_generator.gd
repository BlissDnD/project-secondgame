extends Node
class_name WorldTerrainGenerator

@export var tile_map_layer: TileMapLayer
@export var object_layer: Node2D
@export var tree_scene: PackedScene

@export var world_width_tiles: int = 384
@export var world_height_tiles: int = 144

@export var base_surface_y: int = 13
@export var surface_amplitude: int = 3
@export var noise_frequency: float = 0.02
@export var noise_seed: int = 12345


func _ready() -> void:
	call_deferred("generate")


func generate() -> void:
	print("=== GENERATING NOISE TERRAIN ===")

	if tile_map_layer == null:
		push_error("tile_map_layer is not assigned.")
		return

	tile_map_layer.clear()

	var dirt_cells: Array[Vector2i] = []

	var noise := FastNoiseLite.new()

	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for x in range(world_width_tiles):

		var noise_value := noise.get_noise_1d(float(x))

		var surface_offset := roundi(
			noise_value * surface_amplitude
		)

		var surface_y_for_x := (
			base_surface_y + surface_offset
		)

		for y in range(
			surface_y_for_x,
			world_height_tiles
		):
			dirt_cells.append(Vector2i(x, y))

	tile_map_layer.set_cells_terrain_connect(
		dirt_cells,
		0,
		0,
		true
	)

	# TEST TREE SPAWN
	spawn_tree(Vector2i(10, base_surface_y - 1))

	print("=== NOISE TERRAIN GENERATED ===")


func spawn_tree(cell: Vector2i) -> void:
	print("SPAWN TREE AT: ", cell)

	if tree_scene == null:
		push_error("tree_scene is not assigned.")
		return

	if object_layer == null:
		push_error("object_layer is not assigned.")
		return

	if tile_map_layer == null:
		push_error("tile_map_layer is not assigned.")
		return

	var tree := tree_scene.instantiate()

	object_layer.add_child(tree)

	var local_pos := tile_map_layer.map_to_local(cell)
	var world_pos := tile_map_layer.to_global(local_pos)

	tree.global_position = world_pos

	print("TREE WORLD POS: ", world_pos)
	print("OBJECT COUNT: ", object_layer.get_child_count())
