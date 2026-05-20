extends Node
class_name PlacementOccupancyRegistryClass

var occupied_cells: Dictionary = {}


func _cell_key(cell: Vector2i) -> String:
	return str(cell.x) + ":" + str(cell.y)


func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(_cell_key(cell))


func get_occupant(cell: Vector2i) -> Node:
	var key := _cell_key(cell)
	if not occupied_cells.has(key):
		return null
	return occupied_cells[key]


func are_cells_free(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if is_cell_occupied(cell):
			return false
	return true


func occupy_cells(cells: Array[Vector2i], owner: Node) -> void:
	for cell in cells:
		occupied_cells[_cell_key(cell)] = owner


func release_cells(cells: Array[Vector2i], owner: Node) -> void:
	for cell in cells:
		var key := _cell_key(cell)
		if occupied_cells.has(key) and occupied_cells[key] == owner:
			occupied_cells.erase(key)


func clear_all() -> void:
	occupied_cells.clear()
