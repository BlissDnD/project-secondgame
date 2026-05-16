extends Resource
class_name WorldObjectDefinition

@export var object_id: StringName
@export var display_name: String = ""

@export var max_health: int = 3
@export var size_in_tiles: Vector2i = Vector2i(1, 3)
@export var drops: Array[StringName] = []

@export var scene: PackedScene

@export_group("Spawn")
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.5
@export var spawn_step_tiles: int = 12
@export var min_gap_tiles: int = 4
@export var position_offset_tiles: Vector2i = Vector2i.ZERO
@export var random_x_offset_px: float = 0.0

@export_group("Scale")
@export var scale_min: float = 1.0
@export var scale_max: float = 1.0
