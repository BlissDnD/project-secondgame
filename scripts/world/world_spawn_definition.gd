extends Resource
class_name WorldSpawnDefinition

enum SpawnLocationType {
	SURFACE,
	CAVE_FLOOR,
	CHAMBER
}
@export_group("Placement Validation")
@export var footprint_tiles: Vector2i = Vector2i(1, 1)
@export var minimum_chamber_radius: Vector2i = Vector2i.ZERO
@export var object_id: StringName
@export var scene: PackedScene


@export_group("Location")
@export var spawn_location_type: SpawnLocationType = SpawnLocationType.SURFACE
@export var allowed_terrain_types: Array[StringName] = [&"dirt"]
@export var min_depth_from_surface: int = 0
@export var max_depth_from_surface: int = 999

@export_group("Amount")
@export var max_count: int = -1
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.5
@export var spawn_step_tiles: int = 12
@export var min_gap_tiles: int = 4

@export_group("Placement")
@export var position_offset_tiles: Vector2i = Vector2i.ZERO
@export var random_x_offset_px: float = 0.0

@export_group("Scale")
@export var scale_min: float = 1.0
@export var scale_max: float = 1.0
