extends Resource
class_name NPCDefinition

enum SpawnMode {
	NONE,
	SURFACE_INTERVAL
}

@export var npc_id: StringName
@export var display_name: String = "NPC"
@export var npc_scene: PackedScene

@export_category("Spawn")
@export var spawn_mode: SpawnMode = SpawnMode.SURFACE_INTERVAL
@export var max_count: int = 1
@export var surface_interval_min: int = 80
@export var surface_interval_max: int = 160
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 1.0

@export_category("Movement")
@export var walk_speed: float = 35.0
@export var wander_radius: float = 96.0
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0

@export_category("Interaction")
@export var can_interact: bool = true
@export var interaction_prompt: String = "Talk"

@export_category("Future Dialogue")
@export var dialogue_resource: Resource
