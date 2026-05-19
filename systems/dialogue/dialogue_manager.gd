extends Node

signal dialogue_started(dialogue)
signal dialogue_line_changed(line: DialogueLine, line_index: int)
signal dialogue_choices_changed(choices: Array)
signal dialogue_ended(dialogue)

var current_dialogue: DialogueScriptResource = null
var current_speaker_node: Node2D = null
var current_actor_node: Node2D = null

var nodes: Dictionary = {}
var current_node: DialogueRuntimeNode = null
var current_line_index: int = -1

var is_active: bool = false
var is_showing_choices: bool = false


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
		end_dialogue()


func start_dialogue(
	dialogue: DialogueScriptResource,
	speaker_node: Node2D = null,
	actor_node: Node2D = null
) -> void:
	if dialogue == null:
		push_warning("DialogueManager.start_dialogue() received null dialogue.")
		return

	nodes = DialogueScriptParser.parse_file(dialogue.script_path)

	if nodes.is_empty():
		push_warning("Dialogue script has no nodes: %s" % dialogue.dialogue_id)
		return

	var start_node_id: StringName = &"start"

	if not nodes.has(start_node_id):
		push_warning("Dialogue script missing ::start node: %s" % dialogue.dialogue_id)
		return

	current_dialogue = dialogue
	current_speaker_node = speaker_node
	current_actor_node = actor_node
	current_node = nodes[start_node_id]
	current_line_index = 0
	is_active = true
	is_showing_choices = false

	GameStateManager.set_game_mode(GameStateManager.MODE_DIALOGUE)

	dialogue_started.emit(current_dialogue)
	_emit_current_line()


func advance() -> void:
	if not is_active:
		return

	if current_node == null:
		end_dialogue()
		return

	if is_showing_choices:
		return

	current_line_index += 1

	if current_line_index < current_node.lines.size():
		_emit_current_line()
		return

	if not current_node.choices.is_empty():
		is_showing_choices = true
		dialogue_choices_changed.emit(current_node.choices)
		return

	if current_node.ends_dialogue:
		end_dialogue()
		return

	if current_node.next_node_id != &"":
		_go_to_node(current_node.next_node_id)
		return

	end_dialogue()


func choose(choice_index: int) -> void:
	if not is_active or current_node == null:
		return

	if choice_index < 0 or choice_index >= current_node.choices.size():
		push_warning("Invalid dialogue choice index: %d" % choice_index)
		return

	var choice: DialogueRuntimeChoice = current_node.choices[choice_index]

	if choice.ends_dialogue:
		end_dialogue()
		return

	if choice.target_node_id == &"":
		end_dialogue()
		return

	_go_to_node(choice.target_node_id)


func end_dialogue() -> void:
	var ended_dialogue := current_dialogue

	if ended_dialogue != null:
		GameStateManager.mark_dialogue_seen(ended_dialogue.dialogue_id)

	current_dialogue = null
	current_speaker_node = null
	current_actor_node = null
	current_node = null
	current_line_index = -1
	nodes.clear()
	is_active = false
	is_showing_choices = false

	GameStateManager.set_game_mode(GameStateManager.MODE_EXPLORATION)

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


func _go_to_node(node_id: StringName) -> void:
	if not nodes.has(node_id):
		push_warning("Dialogue node not found: %s" % node_id)
		end_dialogue()
		return

	current_node = nodes[node_id]
	current_line_index = 0
	is_showing_choices = false

	_emit_current_line()


func _emit_current_line() -> void:
	if current_node == null:
		end_dialogue()
		return

	if current_node.lines.is_empty():
		if not current_node.choices.is_empty():
			is_showing_choices = true
			dialogue_choices_changed.emit(current_node.choices)
			return

		if current_node.ends_dialogue:
			end_dialogue()
			return

		if current_node.next_node_id != &"":
			_go_to_node(current_node.next_node_id)
			return

		end_dialogue()
		return

	if current_line_index < 0 or current_line_index >= current_node.lines.size():
		end_dialogue()
		return

	var line := DialogueLine.new()
	line.speaker_name = current_node.speaker_name
	line.text = current_node.lines[current_line_index]

	dialogue_line_changed.emit(line, current_line_index)
