extends Node
class_name SimplePlaceablePlacer

@export var placement_controller: PlacementController
@export var placeable_definition: PlaceableDefinition
@export var placeable_scene: PackedScene
@export var player_body: Node2D
@export var place_distance: float = 48.0
@export var snap_to_nearest_required_node: bool = true
@export var required_node_group: StringName = &"crystal_node"
@export var required_node_side_offset_cells: Vector2i = Vector2i(1, 0)
@export var cell_size: Vector2 = Vector2(32, 32)

var is_active: bool = false


func _ready() -> void:
	call_deferred("_resolve_placement_controller")


func _process(_delta: float) -> void:
	if not is_active:
		return

	var controller := _get_placement_controller()

	if controller == null:
		print("[SimplePlaceablePlacer] missing controller")
		return

	var target_position := _get_target_position()

	if not controller.is_placing:
		controller.begin_placement(placeable_definition, placeable_scene)

	controller.update_preview_from_world_position(target_position)


func begin() -> void:
	var controller := _get_placement_controller()

	if controller == null:
		push_warning("SimplePlaceablePlacer: missing PlacementController.")
		return

	if placeable_definition == null:
		push_warning("SimplePlaceablePlacer: missing PlaceableDefinition.")
		return

	if placeable_scene == null:
		push_warning("SimplePlaceablePlacer: missing PlaceableScene.")
		return

	is_active = true
	controller.begin_placement(placeable_definition, placeable_scene)
	print("[SimplePlaceablePlacer] begin")


func cancel() -> void:
	is_active = false

	var controller := _get_placement_controller()

	if controller != null:
		controller.cancel_placement()

	print("[SimplePlaceablePlacer] cancel")


func confirm() -> Node:
	if not is_active:
		return null

	var controller := _get_placement_controller()

	if controller == null:
		return null

	var placed := controller.try_place_current()

	if placed != null:
		is_active = false

	print("[SimplePlaceablePlacer] confirm placed=", placed)

	return placed


func _get_placement_controller() -> PlacementController:
	if placement_controller != null:
		return placement_controller

	placement_controller = get_tree().get_first_node_in_group("placement_controller") as PlacementController

	if placement_controller != null:
		return placement_controller

	var current_scene := get_tree().current_scene

	if current_scene != null:
		placement_controller = current_scene.find_child("PlacementController", true, false) as PlacementController

	return placement_controller


func _resolve_placement_controller() -> void:
	_get_placement_controller()


func _get_target_position() -> Vector2:
	if snap_to_nearest_required_node:
		var crystal := _find_nearest_required_node()

		if crystal != null:
			var crystal_cell := _world_to_cell(crystal.global_position)
			var target_cell := crystal_cell + required_node_side_offset_cells
			return _cell_to_world(target_cell)

	if player_body == null:
		return Vector2.ZERO

	var facing := 1.0

	if player_body.has_method("get_facing_direction"):
		facing = float(player_body.get_facing_direction())

	return player_body.global_position + Vector2(place_distance * facing, 0.0)


func _find_nearest_required_node() -> Node2D:
	if player_body == null:
		return null

	var nodes := get_tree().get_nodes_in_group(required_node_group)
	var best: Node2D = null
	var best_distance := INF

	for node in nodes:
		var node_2d := node as Node2D

		if node_2d == null:
			continue

		var distance := player_body.global_position.distance_to(node_2d.global_position)

		if distance < best_distance:
			best_distance = distance
			best = node_2d

	return best


func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size.x),
		floori(world_position.y / cell_size.y)
	)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * cell_size.x,
		cell.y * cell_size.y
	)
