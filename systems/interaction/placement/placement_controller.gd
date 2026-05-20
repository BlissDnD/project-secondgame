extends Node
class_name PlacementController

@export var validator: PlacementValidator
@export var preview: PlacementPreview
@export var world_root: Node
@export var cell_size: Vector2 = Vector2(32, 32)

var held_definition: PlaceableDefinition
var held_scene: PackedScene
var is_placing: bool = false
var current_origin_cell: Vector2i = Vector2i.ZERO
var current_valid: bool = false


func begin_placement(definition: PlaceableDefinition, scene: PackedScene) -> void:
	held_definition = definition
	held_scene = scene
	is_placing = true


func cancel_placement() -> void:
	held_definition = null
	held_scene = null
	is_placing = false

	if preview != null:
		preview.clear_preview()


func update_preview_from_world_position(world_position: Vector2) -> void:
	if not is_placing:
		return

	if held_definition == null:
		return

	current_origin_cell = world_to_cell(world_position)

	var cells := validator.get_footprint_cells(current_origin_cell, held_definition.footprint)
	current_valid = validator.is_valid_placement(held_definition, current_origin_cell, world_root)

	if preview != null:
		preview.set_preview(cells, current_valid)


func try_place_current() -> Node:
	if not is_placing:
		return null

	if held_definition == null or held_scene == null:
		return null

	if not current_valid:
		return null

	var instance := held_scene.instantiate()

	if instance is PlaceableObject:
		instance.configure_placeable(held_definition, current_origin_cell)
	else:
		instance.global_position = cell_to_world(current_origin_cell)

	world_root.add_child(instance)

	cancel_placement()

	return instance


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size.x),
		floori(world_position.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size.x, cell.y * cell_size.y)
