extends Resource
class_name WorldObjectDefinition

@export var id: StringName
@export var display_name: String
@export var max_health: int = 3
@export var size_in_tiles: Vector2i = Vector2i(1, 3)
@export var drops: Array[StringName] = []
