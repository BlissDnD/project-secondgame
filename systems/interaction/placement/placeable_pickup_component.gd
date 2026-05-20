extends Area2D
class_name PlaceablePickupComponent

@export var placeable_root: PlaceableObject
@export var definition: PlaceableDefinition
@export var packed_scene: PackedScene

func _ready() -> void:
	if placeable_root == null:
		placeable_root = owner as PlaceableObject

	if definition == null and placeable_root != null:
		definition = placeable_root.definition


func can_pickup() -> bool:
	return placeable_root != null and definition != null and packed_scene != null


func pickup_for_placement(placement_controller: PlacementController) -> bool:
	if not can_pickup():
		return false

	if placement_controller == null:
		return false

	if placeable_root.definition != null and placeable_root.definition.blocks_placement:
		PlacementOccupancyRegistry.release_cells(placeable_root.occupied_cells, placeable_root)

	placement_controller.begin_placement(definition, packed_scene)
	placeable_root.queue_free()

	return true
