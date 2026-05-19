extends Control
class_name DialogueBox

@export var characters_per_second: float = 45.0
@export var bubble_offset: Vector2 = Vector2(0.0, -120.0)

@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SpeakerLabel
@onready var body_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/BodyLabel
@onready var choices_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ChoicesContainer

var full_text: String = ""
var visible_character_count: int = 0
var typewriter_time: float = 0.0
var is_typing: bool = false


func _ready() -> void:
	hide()

	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_line_changed.connect(_on_dialogue_line_changed)
	DialogueManager.dialogue_choices_changed.connect(_on_dialogue_choices_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _process(delta: float) -> void:
	_update_position()

	if not is_typing:
		return

	typewriter_time += delta
	visible_character_count = int(typewriter_time * characters_per_second)

	if visible_character_count >= full_text.length():
		_finish_typewriter()
		return

	body_label.text = full_text.substr(0, visible_character_count)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()

		if is_typing:
			_finish_typewriter()
			return

		DialogueManager.advance()


func _on_dialogue_started(_dialogue) -> void:
	show()
	_clear_choices()


func _on_dialogue_line_changed(line: DialogueLine, _line_index: int) -> void:
	_clear_choices()

	speaker_label.text = line.speaker_name
	full_text = line.text

	_start_typewriter()


func _on_dialogue_choices_changed(choices: Array) -> void:
	_clear_choices()
	_finish_typewriter()

	for i in choices.size():
		var choice = choices[i]

		var button := Button.new()
		button.text = choice.label

		button.pressed.connect(func() -> void:
			DialogueManager.choose(i)
		)

		choices_container.add_child(button)


func _on_dialogue_ended(_dialogue) -> void:
	hide()
	_clear_choices()
	_reset_typewriter()


func _start_typewriter() -> void:
	typewriter_time = 0.0
	visible_character_count = 0
	is_typing = true
	body_label.text = ""


func _finish_typewriter() -> void:
	is_typing = false
	visible_character_count = full_text.length()
	body_label.text = full_text


func _reset_typewriter() -> void:
	full_text = ""
	visible_character_count = 0
	typewriter_time = 0.0
	is_typing = false
	body_label.text = ""


func _update_position() -> void:
	if not visible:
		return

	if DialogueManager.current_speaker_node == null:
		return

	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_pos: Vector2 = DialogueManager.current_speaker_node.global_position
	var screen_pos: Vector2 = canvas_transform * world_pos

	global_position = screen_pos + Vector2(-size.x * 0.5, 0.0) + bubble_offset


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
