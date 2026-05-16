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

@export var tree_spawn_step: int = 6
@export var tree_spawn_chance: float = 0.35


func _ready() -> void:
	call_deferred("generate")


func generate() -> void:
	print("=== GENERATING NOISE TERRAIN ===")

	if tile_map_layer == null:
		push_error("tile_map_layer is not assigned.")
		return

	tile_map_layer.clear()
	clear_objects()

	var dirt_cells: Array[Vector2i] = []

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	for x in range(world_width_tiles):
		var surface_y_for_x := get_surface_y_for_x(x, noise)

		for y in range(surface_y_for_x, world_height_tiles):
			dirt_cells.append(Vector2i(x, y))

	tile_map_layer.set_cells_terrain_connect(
		dirt_cells,
		0,
		0,
		true
	)

	spawn_trees_on_surface(noise)

	print("Dirt cells: ", dirt_cells.size())
	print("Objects: ", object_layer.get_child_count() if object_layer != null else 0)
	print("=== NOISE TERRAIN GENERATED ===")


func get_surface_y_for_x(x: int, noise: FastNoiseLite) -> int:
	var noise_value := noise.get_noise_1d(float(x))
	var surface_offset := roundi(noise_value * surface_amplitude)
	return base_surface_y + surface_offset


func spawn_trees_on_surface(noise: FastNoiseLite) -> void:
	if tree_scene == null:
		push_error("tree_scene is not assigned.")
		return

	if object_layer == null:
		push_error("object_layer is not assigned.")
		return

	for x in range(0, world_width_tiles, tree_spawn_step):
		if randf() > tree_spawn_chance:
			continue

		var surface_y_for_x := get_surface_y_for_x(x, noise)
		var tree_cell := Vector2i(x, surface_y_for_x - 1)

		spawn_tree(tree_cell)


func spawn_tree(cell: Vector2i) -> void:
	var tree := tree_scene.instantiate()
	object_layer.add_child(tree)

	var local_pos := tile_map_layer.map_to_local(cell)
	var world_pos := tile_map_layer.to_global(local_pos)

	tree.global_position = world_pos


func clear_objects() -> void:
	if object_layer == null:
		return

	for child in object_layer.get_children():
		child.queue_free()
