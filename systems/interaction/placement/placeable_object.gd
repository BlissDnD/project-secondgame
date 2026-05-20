extends Node2D
class_name PlaceableObject

@export var definition: PlaceableDefinition
@export var origin_cell: Vector2i = Vector2i.ZERO
@export var cell_size: Vector2 = Vector2(32, 32)

var occupied_cells: Array[Vector2i] = []


func _ready() -> void:
	if definition == null:
		push_warning("PlaceableObject has no PlaceableDefinition.")
		return

	occupied_cells = _calculate_occupied_cells()

	if definition.blocks_placement:
		PlacementOccupancyRegistry.occupy_cells(occupied_cells, self)


func _exit_tree() -> void:
	if definition != null and definition.blocks_placement:
		PlacementOccupancyRegistry.release_cells(occupied_cells, self)


func configure_placeable(new_definition: PlaceableDefinition, new_origin_cell: Vector2i) -> void:
	definition = new_definition
	origin_cell = new_origin_cell
	global_position = Vector2(origin_cell.x * cell_size.x, origin_cell.y * cell_size.y)


func _calculate_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if definition == null:
		return cells

	for y in range(definition.footprint.y):
		for x in range(definition.footprint.x):
			cells.append(origin_cell + Vector2i(x, y))

	return cells
