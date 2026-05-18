extends Node

signal dialogue_started(dialogue: DialogueResource)
signal dialogue_line_changed(line: DialogueLine, line_index: int)
signal dialogue_choices_changed(choices: Array[DialogueChoice])
signal dialogue_ended(dialogue: DialogueResource)

var current_dialogue: DialogueResource = null
var current_speaker_node: Node2D = null
var current_actor_node: Node2D = null
var current_line_index: int = -1
var is_active: bool = false


func _process(_delta: float) -> void:
	if not is_active:
		return

	if current_dialogue == null:
		return

	if not current_dialogue.close_on_distance:
		return

	if current_speaker_node == null or current_actor_node == null:
		return

	var distance: float = current_speaker_node.global_position.distance_to(current_actor_node.global_position)

	if distance > current_dialogue.max_distance:
		print("Dialogue closed because actor moved too far. Distance: ", distance)
		end_dialogue()


func start_dialogue(
	dialogue: DialogueResource,
	speaker_node: Node2D = null,
	actor_node: Node2D = null
) -> void:
	if dialogue == null:
		push_warning("DialogueManager.start_dialogue() received null dialogue.")
		return

	if dialogue.lines.is_empty():
		push_warning("Dialogue has no lines: %s" % dialogue.dialogue_id)
		return

	current_dialogue = dialogue
	current_speaker_node = speaker_node
	current_actor_node = actor_node
	current_line_index = 0
	is_active = true

	dialogue_started.emit(current_dialogue)
	_emit_current_line()


func advance() -> void:
	if not is_active or current_dialogue == null:
		return

	current_line_index += 1

	if current_line_index >= current_dialogue.lines.size():
		_show_choices_or_end()
		return

	_emit_current_line()


func choose(choice_index: int) -> void:
	if not is_active or current_dialogue == null:
		return

	if choice_index < 0 or choice_index >= current_dialogue.choices.size():
		push_warning("Invalid dialogue choice index: %d" % choice_index)
		return

	var choice := current_dialogue.choices[choice_index]

	if choice.ends_dialogue:
		end_dialogue()
		return

	if choice.next_line_index >= 0 and choice.next_line_index < current_dialogue.lines.size():
		current_line_index = choice.next_line_index
		_emit_current_line()
	else:
		end_dialogue()


func end_dialogue() -> void:
	var ended_dialogue: DialogueResource = current_dialogue

	current_dialogue = null
	current_speaker_node = null
	current_actor_node = null
	current_line_index = -1
	is_active = false

	if ended_dialogue != null:
		dialogue_ended.emit(ended_dialogue)


func should_lock_player_input() -> bool:
	if current_dialogue == null:
		return false

	return current_dialogue.lock_player_input


func should_pause_speaker_movement() -> bool:
	if current_dialogue == null:
		return false

	return current_dialogue.pause_speaker_movement


func _emit_current_line() -> void:
	if current_dialogue == null:
		return

	var line: DialogueLine = current_dialogue.lines[current_line_index]
	dialogue_line_changed.emit(line, current_line_index)


func _show_choices_or_end() -> void:
	if current_dialogue == null:
		return

	if current_dialogue.choices.is_empty():
		end_dialogue()
	else:
		dialogue_choices_changed.emit(current_dialogue.choices)
