extends Node2D


func _ready() -> void:
	var sim_entity := get_node_or_null("SimulationEntityComponent")

	if sim_entity != null:
		sim_entity.simulation_activated.connect(_on_simulation_activated)
		sim_entity.simulation_deactivated.connect(_on_simulation_deactivated)


func _on_simulation_activated() -> void:
	print(name, " SIMULATION ACTIVATED")


func _on_simulation_deactivated() -> void:
	print(name, " SIMULATION DEACTIVATED")
