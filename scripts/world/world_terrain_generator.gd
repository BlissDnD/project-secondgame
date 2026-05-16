extends Node
class_name WorldTerrainGenerator2

@export var tile_map_layer: TileMapLayer
@export var object_layer: Node2D
@export var crashed_ship_scene: PackedScene
@export var world_width_tiles: int = 384
@export var world_height_tiles: int = 144
@export var base_surface_y: int = 13
@export var surface_amplitude: int = 3
@export var noise_frequency: float = 0.02
@export var noise_seed: int = 12345
@export_group("World Objects")
@export var world_objects: Array[WorldObjectDefinition] = []


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

	spawn_world_objects_on_surface(noise)
	spawn_crashed_ship(noise)
	print("Dirt cells: ", dirt_cells.size())
	print("Objects: ", object_layer.get_child_count() if object_layer != null else 0)
	print("=== WORLD GENERATED ===")


func get_surface_y_for_x(x: int, noise: FastNoiseLite) -> int:
	var noise_value := noise.get_noise_1d(float(x))
	var surface_offset := roundi(noise_value * surface_amplitude)
	return base_surface_y + surface_offset


func spawn_world_objects_on_surface(noise: FastNoiseLite) -> void:
	if object_layer == null:
		push_error("object_layer is not assigned.")
		return

	for definition in world_objects:
		if definition == null:
			continue

		if definition.scene == null:
			push_error("WorldObjectDefinition has no scene: " + str(definition.object_id))
			continue

		spawn_definition_on_surface(definition, noise)


func spawn_definition_on_surface(
	definition: WorldObjectDefinition,
	noise: FastNoiseLite
) -> void:
	var last_spawn_x := -999999
	var step: int = maxi(definition.spawn_step_tiles, 1)

	for x in range(0, world_width_tiles, step):
		if randf() > definition.spawn_chance:
			continue

		if x - last_spawn_x < definition.min_gap_tiles:
			continue

		var surface_y_for_x := get_surface_y_for_x(x, noise)

		var ground_cell := Vector2i(
			x + definition.position_offset_tiles.x,
			surface_y_for_x + definition.position_offset_tiles.y
		)

		spawn_world_object_on_cell_top(definition, ground_cell)

		last_spawn_x = x


func spawn_world_object_on_cell_top(
	definition: WorldObjectDefinition,
	cell: Vector2i
) -> void:
	var object := definition.scene.instantiate()
	object_layer.add_child(object)

	var tile_size := Vector2(tile_map_layer.tile_set.tile_size)

	var local_cell_top := Vector2(
		cell.x * tile_size.x + tile_size.x * 0.5,
		cell.y * tile_size.y
	)

	local_cell_top.x += randf_range(
		-definition.random_x_offset_px,
		definition.random_x_offset_px
	)

	var world_pos := tile_map_layer.to_global(local_cell_top)
	object.global_position = world_pos

	var random_scale := randf_range(
		definition.scale_min,
		definition.scale_max
	)

	object.scale = Vector2.ONE * random_scale


func clear_objects() -> void:
	if object_layer == null:
		return

	for child in object_layer.get_children():
		child.queue_free()
func spawn_crashed_ship(noise: FastNoiseLite) -> void:
	if crashed_ship_scene == null:
		return

	var spawn_x := 12

	var surface_y := get_surface_y_for_x(
		spawn_x,
		noise
	)

	var ship := crashed_ship_scene.instantiate()

	object_layer.add_child(ship)

	var tile_size := Vector2(
		tile_map_layer.tile_set.tile_size
	)

	var local_pos := Vector2(
		spawn_x * tile_size.x,
		surface_y * tile_size.y
	)

	var world_pos := tile_map_layer.to_global(local_pos)

	ship.global_position = world_pos
