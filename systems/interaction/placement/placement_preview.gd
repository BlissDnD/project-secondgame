extends Node2D
class_name PlacementPreview

@export var valid_color: Color = Color(0.1, 1.0, 0.25, 0.35)
@export var invalid_color: Color = Color(1.0, 0.1, 0.1, 0.35)

var preview_rects: Array[Rect2] = []
var is_valid: bool = false


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 999
	z_as_relative = false
	visible = true


func set_preview_rects(rects: Array[Rect2], valid: bool) -> void:
	is_valid = valid

	if not valid:
		preview_rects.clear()
		visible = false
		queue_redraw()
		return

	preview_rects = rects
	top_level = true
	global_position = Vector2.ZERO
	z_index = 999
	z_as_relative = false
	visible = true
	queue_redraw()


func clear_preview() -> void:
	preview_rects.clear()
	queue_redraw()


func _draw() -> void:
	var draw_color := valid_color

	if not is_valid:
		draw_color = invalid_color

	for rect in preview_rects:
		draw_rect(rect, draw_color, true)
		draw_rect(
			rect,
			Color(draw_color.r, draw_color.g, draw_color.b, 0.95),
			false,
			2.0
		)
