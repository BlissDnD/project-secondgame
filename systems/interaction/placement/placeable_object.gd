extends Node2D
class_name PlaceableObject

@export var definition: PlaceableDefinition
@export var origin_cell: Vector2i = Vector2i.ZERO
@export var cell_size: Vector2 = Vector2(32, 32)

var occupied_cells: Array[Vector2i] = []
var is_configured: bool = false
var has_registered_occupancy: bool = false


func _ready() -> void:
	if definition != null and not is_configured:
		configure_placeable(definition, origin_cell)


func _exit_tree() -> void:
	_release_occupancy()


func configure_placeable(new_definition: PlaceableDefinition, new_origin_cell: Vector2i) -> void:
	_release_occupancy()

	definition = new_definition
	origin_cell = new_origin_cell
	is_configured = true

	global_position = Vector2(origin_cell.x * cell_size.x, origin_cell.y * cell_size.y)

	occupied_cells = _calculate_occupied_cells()

	if definition != null and definition.blocks_placement:
		PlacementOccupancyRegistry.occupy_cells(occupied_cells, self)
		has_registered_occupancy = true


func _release_occupancy() -> void:
	if not has_registered_occupancy:
		return

	if definition != null and definition.blocks_placement:
		PlacementOccupancyRegistry.release_cells(occupied_cells, self)

	has_registered_occupancy = false
	occupied_cells.clear()


func _calculate_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if definition == null:
		return cells

	for y in range(definition.footprint.y):
		for x in range(definition.footprint.x):
			cells.append(origin_cell + Vector2i(x, y))

	return cells
