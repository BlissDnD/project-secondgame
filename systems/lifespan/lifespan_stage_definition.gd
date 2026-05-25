class_name LifeSpanStageDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_range(0.0, 1.0, 0.01) var starts_at_progress: float = 0.0
@export var sprite_texture: Texture2D
