extends Control
class_name BarkBubble

@export var bubble_offset: Vector2 = Vector2(0.0, -90.0)

@onready var body_label: RichTextLabel = $PanelContainer/MarginContainer/BodyLabel

var speaker_node: Node2D = null
var hide_timer: float = 0.0


func _ready() -> void:
	hide()

	BarkManager.bark_requested.connect(_on_bark_requested)


func _process(delta: float) -> void:
	if not visible:
		return

	_update_position()

	hide_timer -= delta

	if hide_timer <= 0.0:
		hide()


func _on_bark_requested(text: String, target_speaker_node: Node2D, duration: float) -> void:
	speaker_node = target_speaker_node
	hide_timer = duration
	body_label.text = text
	show()
	_update_position()


func _update_position() -> void:
	if speaker_node == null:
		return

	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_pos: Vector2 = speaker_node.global_position
	var screen_pos: Vector2 = canvas_transform * world_pos

	global_position = screen_pos + Vector2(-size.x * 0.5, 0.0) + bubble_offset
