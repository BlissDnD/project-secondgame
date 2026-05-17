extends Node
class_name NPCSpawner

@export var npc_definitions: Array[NPCDefinition] = []
@export var world_root: NodePath

var spawned_counts: Dictionary = {}

@onready var _world_root_node: Node = get_node_or_null(world_root)

func spawn_surface_npcs(surface_cells: Array[Vector2i], tile_size: int = 32) -> void:
	if _world_root_node == null:
		_world_root_node = get_tree().current_scene

	for definition in npc_definitions:
		if definition == null:
			continue

		if definition.spawn_mode != NPCDefinition.SpawnMode.SURFACE_INTERVAL:
			continue

		_spawn_surface_interval_npc(definition, surface_cells, tile_size)

func _spawn_surface_interval_npc(definition: NPCDefinition, surface_cells: Array[Vector2i], tile_size: int) -> void:
	if definition.npc_scene == null:
		push_warning("NPCDefinition '%s' has no npc_scene." % definition.npc_id)
		return

	var current_count := int(spawned_counts.get(definition.npc_id, 0))
	if current_count >= definition.max_count:
		return

	if randf() > definition.spawn_chance:
		return

	if surface_cells.is_empty():
		return

	var interval := randi_range(definition.surface_interval_min, definition.surface_interval_max)
	var start_index := randi_range(0, max(surface_cells.size() - 1, 0))

	for i in range(start_index, surface_cells.size(), interval):
		var cell := surface_cells[i]
		var world_pos := Vector2(cell.x * tile_size + tile_size * 0.5, cell.y * tile_size)

		_spawn_npc(definition, world_pos)

		current_count += 1
		spawned_counts[definition.npc_id] = current_count

		if current_count >= definition.max_count:
			return

func _spawn_npc(definition: NPCDefinition, world_position: Vector2) -> Node:
	var npc_instance := definition.npc_scene.instantiate()
	_world_root_node.add_child(npc_instance)
	npc_instance.global_position = world_position

	if npc_instance.has_method("setup"):
		npc_instance.setup(definition, world_position)

	return npc_instance
