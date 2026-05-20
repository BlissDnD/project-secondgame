extends Resource
class_name PlaceableDefinition

@export var display_name: String = "Placeable"

@export var footprint: Vector2i = Vector2i(1, 1)

@export var placement_mode: PlacementTypes.PlacementMode = PlacementTypes.PlacementMode.GROUNDED_ALL

@export var blocks_placement: bool = true

@export var required_node_group: String = ""
@export var required_node_radius_tiles: int = 0

@export var allowed_terrain_types: Array[StringName] = []
