extends Resource
class_name IdleDialogueResource

@export_multiline var lines: Array[String] = []

@export_category("Timing")
@export var min_interval: float = 4.0
@export var max_interval: float = 9.0
@export var display_duration: float = 2.5

@export_category("Rules")
@export var chance: float = 1.0
@export var require_player_nearby: bool = true
@export var max_distance: float = 180.0
@export var cooldown_after_interaction: float = 4.0
