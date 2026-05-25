extends Label

@export var world_simulation_manager_path: NodePath

var _world_simulation_manager: Node


func _ready() -> void:
	call_deferred("_initialize")


func _process(_delta: float) -> void:
	if _world_simulation_manager == null:
		return

	_update_text()


func _initialize() -> void:
	if world_simulation_manager_path.is_empty():
		push_error("WorldSimulationDebugDisplay missing world_simulation_manager_path.")
		return

	_world_simulation_manager = get_node_or_null(world_simulation_manager_path)

	if _world_simulation_manager == null:
		push_error("WorldSimulationDebugDisplay could not resolve WorldSimulationManager.")
		return

	_update_text()


func _update_text() -> void:
	var player: Node2D = _world_simulation_manager.get("_player")

	if player == null:
		text = "WorldSim: no player"
		return

	var zone_registry := get_node_or_null("/root/SimulationZoneRegistry")

	if zone_registry == null:
		text = "WorldSim: no SimulationZoneRegistry"
		return

	var player_zone_id: Vector2i = zone_registry.call(
		"get_zone_id_for_world_position",
		player.global_position
	)

	var active_zones: Array = _world_simulation_manager.call("get_active_zones")

	var lines: Array[String] = []

	lines.append("--- WORLD SIM ---")
	lines.append("PLAYER ZONE: %s" % str(player_zone_id))
	lines.append("ACTIVE ZONES: %s" % active_zones.size())
	lines.append("ACTIVE RADIUS: %s" % _world_simulation_manager.active_zone_radius)

	text = "\n".join(lines)
