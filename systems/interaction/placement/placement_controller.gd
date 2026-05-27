extends Node
class_name PlacementController

@export var validator: PlacementValidator
@export var preview: PlacementPreview
@export var world_root: Node
@export var cell_size: Vector2 = Vector2(32, 32)

@export var debug_enabled: bool = false

var held_definition: PlaceableDefinition
var held_scene: PackedScene
var is_placing: bool = false
var current_origin_cell: Vector2i = Vector2i.ZERO
var current_valid: bool = false

var _references_logged: bool = false


func _ready() -> void:
	add_to_group("placement_controller")
	call_deferred("_resolve_references")


func _resolve_references() -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	if validator == null:
		validator = current_scene.find_child("PlacementValidator", true, false) as PlacementValidator

	if preview == null:
		preview = current_scene.find_child("PlacementPreview", true, false) as PlacementPreview

	if world_root == null:
		world_root = current_scene.find_child("ObjectLayer", true, false)

	if world_root == null:
		push_warning("PlacementController: ObjectLayer not found. Falling back to current_scene.")
		world_root = current_scene

	if debug_enabled and not _references_logged:
		print("[PlacementController] validator=", validator)
		print("[PlacementController] preview=", preview)
		print("[PlacementController] world_root=", world_root)
		_references_logged = true


func begin_placement(definition: PlaceableDefinition, scene: PackedScene) -> void:
	if validator == null or preview == null or world_root == null:
		_resolve_references()

	if definition == null:
		push_warning("PlacementController.begin_placement: null definition.")
		return

	if scene == null:
		push_warning("PlacementController.begin_placement: null scene.")
		return

	held_definition = definition
	held_scene = scene
	is_placing = true
	current_valid = false


func cancel_placement() -> void:
	held_definition = null
	held_scene = null
	is_placing = false
	current_valid = false

	if preview != null:
		preview.clear_preview()


func update_preview_from_world_position(world_position: Vector2) -> void:
	if not is_placing:
		return

	if held_definition == null:
		return

	if validator == null or preview == null or world_root == null:
		_resolve_references()

	if validator == null:
		push_warning("PlacementController.update_preview: missing validator.")
		current_valid = false
		return

	if preview == null:
		push_warning("PlacementController.update_preview: missing preview.")
		current_valid = false
		return

	if world_root == null:
		push_warning("PlacementController.update_preview: missing world_root.")
		current_valid = false
		return

	current_origin_cell = world_to_cell(world_position)

	var cells := validator.get_footprint_cells(current_origin_cell, held_definition.footprint)
	current_valid = validator.is_valid_placement(held_definition, current_origin_cell, world_root)

	var rects: Array[Rect2] = []

	for cell in cells:
		rects.append(Rect2(
			cell_to_world(cell),
			cell_size
		))

	preview.set_preview_rects(rects, current_valid)

	if debug_enabled and Engine.get_process_frames() % 30 == 0:
		print(
			"[PLACE] cell=", current_origin_cell,
			" valid=", current_valid
		)


func try_place_current() -> Node:
	if not is_placing:
		return null

	if held_definition == null or held_scene == null:
		return null

	if not current_valid:
		if debug_enabled:
			print("[PLACE] cannot place: current_valid=false")
		return null

	if world_root == null:
		_resolve_references()

	if world_root == null:
		return null

	var instance := held_scene.instantiate()

	world_root.add_child(instance)

	if instance is PlaceableObject:
		var placeable := instance as PlaceableObject
		placeable.configure_placeable(held_definition, current_origin_cell)
	else:
		if instance is Node2D:
			(instance as Node2D).global_position = cell_to_world(current_origin_cell)

	cancel_placement()

	if debug_enabled:
		print("[PLACE] placed instance=", instance)

	return instance


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size.x),
		floori(world_position.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size.x, cell.y * cell_size.y)
