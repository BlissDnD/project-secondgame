extends Resource
class_name PlaceableDefinition

@export var display_name: String = ""
@export var footprint: Vector2i = Vector2i.ONE
@export var placement_mode: PlacementTypes.PlacementMode = PlacementTypes.PlacementMode.GROUNDED
@export var blocks_placement: bool = true

@export var required_node_group: StringName = &""
@export var required_node_radius_tiles: int = 0
@export var allowed_terrain_types: Array[StringName] = []

@export_group("Context Placement")
@export var use_context_placement: bool = false
@export var context_required_group: StringName = &""
@export var context_required_radius: float = 128.0
@export var context_side_offset_cells: Vector2i = Vector2i(1, 0)
@export var context_cell_size: Vector2 = Vector2(32, 32)
