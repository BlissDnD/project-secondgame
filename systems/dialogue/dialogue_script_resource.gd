extends Resource
class_name DialogueScriptResource

@export var dialogue_id: StringName
@export_file("*.dialogue", "*.txt") var script_path: String

@export_category("Behavior")
@export var lock_player_input: bool = false
@export var pause_speaker_movement: bool = true
@export var close_on_distance: bool = true
@export var max_distance: float = 96.0
