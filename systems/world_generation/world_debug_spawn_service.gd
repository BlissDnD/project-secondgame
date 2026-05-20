extends Node
class_name WorldDebugSpawnService

@export var main_crystal_scene: PackedScene
@export var crystal_node_scene: PackedScene
@export var worker_scene: PackedScene
@export var crystal_station_scene: PackedScene

@export var spawn_origin: Node2D
@export var terrain_provider: Node

@export var spawn_offset_x: float = 160.0
@export var object_spacing: float = 96.0
@export var vertical_offset: float = -32.0

var has_spawned: bool = false


func spawn_test_worker_loop_objects() -> void:
	if has_spawned:
		return

	if spawn_origin == null:
		push_warning("WorldDebugSpawnService: spawn_origin is missing.")
		return

	var base_x := spawn_origin.global_position.x + spawn_offset_x
	var surface_y := _get_surface_y(base_x)

	var main_crystal := _spawn_scene(
		main_crystal_scene,
		Vector2(base_x, surface_y + vertical_offset)
	)

	var crystal_node := _spawn_scene(
		crystal_node_scene,
		Vector2(base_x + object_spacing * 2.0, surface_y + vertical_offset)
	)

	var worker := _spawn_scene(
		worker_scene,
		Vector2(base_x + object_spacing * 3.0, surface_y + vertical_offset)
	)

	var station := _spawn_scene(
		crystal_station_scene,
		Vector2(base_x + object_spacing * 2.0 + 32.0, surface_y + vertical_offset)
	)

	has_spawned = true

	print("Spawned worker loop debug objects: ", main_crystal, " ", crystal_node, " ", worker, " ", station)


func _spawn_scene(scene: PackedScene, position: Vector2) -> Node:
	if scene == null:
		push_warning("WorldDebugSpawnService: missing PackedScene.")
		return null

	var instance := scene.instantiate()
	get_tree().current_scene.add_child(instance)

	if instance is Node2D:
		instance.global_position = position

	return instance


func _get_surface_y(x: float) -> float:
	if terrain_provider != null:
		if terrain_provider.has_method("get_surface_y_for_x"):
			return terrain_provider.get_surface_y_for_x(x)

		if terrain_provider.has_method("get_surface_y"):
			return terrain_provider.get_surface_y(x)

	return spawn_origin.global_position.y
