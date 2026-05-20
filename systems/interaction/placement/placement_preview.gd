extends Node2D
class_name PlacementPreview

@export var cell_size: Vector2 = Vector2(32, 32)

var preview_cells: Array[Vector2i] = []
var is_valid: bool = false


func set_preview(cells: Array[Vector2i], valid: bool) -> void:
	preview_cells = cells
	is_valid = valid
	queue_redraw()


func clear_preview() -> void:
	preview_cells.clear()
	queue_redraw()


func _draw() -> void:
	var color := Color(0.1, 1.0, 0.25, 0.35)

	if not is_valid:
		color = Color(1.0, 0.1, 0.1, 0.35)

	for cell in preview_cells:
		var rect := Rect2(
			Vector2(cell.x * cell_size.x, cell.y * cell_size.y),
			cell_size
		)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(color.r, color.g, color.b, 0.9), false, 2.0)
