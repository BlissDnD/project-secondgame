extends Resource
class_name DialogueResource

@export var dialogue_id: StringName
@export var lines: Array[DialogueLine] = []
@export var choices: Array[DialogueChoice] = []

@export_category("Behavior")
@export var lock_player_input: bool = false
@export var pause_speaker_movement: bool = true
@export var close_on_distance: bool = true
@export var max_distance: float = 96.0
