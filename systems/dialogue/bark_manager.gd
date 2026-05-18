extends Node

signal bark_requested(text: String, speaker_node: Node2D, duration: float)

var player_node: Node2D = null


func set_player(player: Node2D) -> void:
	player_node = player


func try_show_idle_bark(
	idle_dialogue: IdleDialogueResource,
	speaker_node: Node2D
) -> void:
	if idle_dialogue == null:
		return

	if speaker_node == null:
		return

	if DialogueManager.is_active:
		return

	if idle_dialogue.lines.is_empty():
		return

	if randf() > idle_dialogue.chance:
		return

	if idle_dialogue.require_player_nearby:
		if player_node == null:
			return

		var distance: float = speaker_node.global_position.distance_to(player_node.global_position)

		if distance > idle_dialogue.max_distance:
			return

	var text: String = idle_dialogue.lines.pick_random()
	bark_requested.emit(text, speaker_node, idle_dialogue.display_duration)
