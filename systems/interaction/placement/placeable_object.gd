extends Node2D
class_name PlaceableObject

@export var definition: PlaceableDefinition
@export var origin_cell: Vector2i = Vector2i.ZERO
@export var cell_size: Vector2 = Vector2(32, 32)

@export_group("Placement Anchor")
@export var placement_anchor_offset: Vector2 = Vector2.ZERO

var occupied_cells: Array[Vector2i] = []
var is_configured: bool = false
var has_registered_occupancy: bool = false


func _ready() -> void:
	if definition != null and not is_configured:
		configure_placeable(definition, origin_cell)


func _exit_tree() -> void:
	_release_occupancy()


# =========================
# PUBLIC API
# =========================

func configure_placeable(
	new_definition: PlaceableDefinition,
	new_origin_cell: Vector2i
) -> void:
	_release_occupancy()

	definition = new_definition
	origin_cell = new_origin_cell
	is_configured = true

	global_position = cell_to_world(origin_cell) + placement_anchor_offset

	occupied_cells = _calculate_occupied_cells()

	if definition != null and definition.blocks_placement:
		PlacementOccupancyRegistry.occupy_cells(
			occupied_cells,
			self
		)

		has_registered_occupancy = true


func move_to_cell(new_origin_cell: Vector2i) -> void:
	configure_placeable(definition, new_origin_cell)


func get_placeable_definition() -> PlaceableDefinition:
	return definition


func get_placeable_scene() -> PackedScene:
	if scene_file_path == "":
		return null

	var loaded := load(scene_file_path)

	if loaded is PackedScene:
		return loaded as PackedScene

	return null


func can_be_context_placed() -> bool:
	return definition != null


func get_origin_cell() -> Vector2i:
	return origin_cell


func get_occupied_cells() -> Array[Vector2i]:
	return occupied_cells.duplicate()


# =========================
# GRID HELPERS
# =========================

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * cell_size.x,
		cell.y * cell_size.y
	)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size.x),
		floori(world_position.y / cell_size.y)
	)


# =========================
# OCCUPANCY
# =========================

func _release_occupancy() -> void:
	if not has_registered_occupancy:
		return

	if definition != null and definition.blocks_placement:
		PlacementOccupancyRegistry.release_cells(
			occupied_cells,
			self
		)

	has_registered_occupancy = false
	occupied_cells.clear()


func _calculate_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if definition == null:
		return cells

	for y in range(definition.footprint.y):
		for x in range(definition.footprint.x):
			cells.append(
				origin_cell + Vector2i(x, y)
			)

	return cells
