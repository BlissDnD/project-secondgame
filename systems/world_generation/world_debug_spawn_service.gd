extends Node
class_name WorldDebugSpawnService

@export var main_crystal_scene: PackedScene
@export var crystal_node_scene: PackedScene
@export var worker_scene: PackedScene
@export var crystal_station_scene: PackedScene

@export var spawn_origin: Node2D
@export var terrain_provider: Node

@export var spawn_offset_x: float = 450.0
@export var object_spacing: float = 180.0
@export var vertical_offset: float = 0.0

var has_spawned: bool = false


func spawn_test_worker_loop_objects() -> void:
	if has_spawned:
		return

	if spawn_origin == null:
		push_warning("WorldDebugSpawnService: spawn_origin is missing.")
		return

	var base_x: float = spawn_origin.global_position.x + spawn_offset_x

	var main_x: float = base_x
	var node_x: float = base_x + object_spacing
	var station_x: float = base_x + object_spacing * 2.0
	var worker_x: float = base_x + object_spacing * 3.0

	_spawn_on_surface(main_crystal_scene, main_x, "MainCrystal")
	_spawn_on_surface(crystal_node_scene, node_x, "CrystalNode")
	_spawn_on_surface(crystal_station_scene, station_x, "CrystalNodeStation")
	_spawn_on_surface(worker_scene, worker_x, "Worker")

	has_spawned = true


func _spawn_on_surface(scene: PackedScene, x: float, debug_name: String) -> Node:
	if scene == null:
		push_warning("WorldDebugSpawnService: missing scene for " + debug_name)
		return null

	var surface_y: float = _get_surface_y(x)

	var instance := scene.instantiate()
	get_tree().current_scene.add_child(instance)

	if instance is Node2D:
		instance.global_position = Vector2(x, surface_y + vertical_offset)
		print(
			debug_name,
			" spawned at x=",
			x,
			" surface_y=",
			surface_y,
			" final=",
			instance.global_position
		)

	return instance


func _get_surface_y(x: float) -> float:
	if terrain_provider != null:
		if terrain_provider.has_method("get_surface_y_for_x"):
			return terrain_provider.get_surface_y_for_x(x)

		if terrain_provider.has_method("get_surface_y"):
			return terrain_provider.get_surface_y(x)

	push_warning("WorldDebugSpawnService: terrain_provider has no surface_y method.")
	return spawn_origin.global_position.y
