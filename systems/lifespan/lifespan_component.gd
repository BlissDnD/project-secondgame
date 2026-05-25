class_name LifeSpanComponent
extends Node

signal stage_changed(new_stage: LifeSpanStageDefinition)
signal lifespan_finished

@export var definition: LifeSpanDefinition
@export var auto_start: bool = true
@export var age_minutes: int = 0
@export var simulate_while_dormant: bool = true

var current_stage: LifeSpanStageDefinition
var _is_finished: bool = false
var _simulation_active: bool = true


func _ready() -> void:
	if definition == null:
		push_warning("LifeSpanComponent has no LifeSpanDefinition assigned.")
		return

	if auto_start:
		_refresh_stage(true)

	if get_node_or_null("/root/SimulationTickService") != null:
		if not SimulationTickService.minute_simulation_tick.is_connected(_on_minute_tick):
			SimulationTickService.minute_simulation_tick.connect(_on_minute_tick)

	call_deferred("_connect_simulation_entity")


func _exit_tree() -> void:
	if get_node_or_null("/root/SimulationTickService") != null:
		if SimulationTickService.minute_simulation_tick.is_connected(_on_minute_tick):
			SimulationTickService.minute_simulation_tick.disconnect(_on_minute_tick)


func _connect_simulation_entity() -> void:
	var sim_entity := _find_simulation_entity_component()

	if sim_entity == null:
		return

	if not sim_entity.simulation_activated.is_connected(_on_simulation_activated):
		sim_entity.simulation_activated.connect(_on_simulation_activated)

	if not sim_entity.simulation_deactivated.is_connected(_on_simulation_deactivated):
		sim_entity.simulation_deactivated.connect(_on_simulation_deactivated)


func _on_minute_tick(_total_minutes: int) -> void:
	if definition == null:
		return

	if _is_finished:
		return

	if not _simulation_active and not simulate_while_dormant:
		return

	advance_lifespan_minutes(1)


func advance_lifespan_minutes(minutes: int) -> void:
	if minutes <= 0:
		return

	if definition == null:
		return

	if _is_finished:
		return

	age_minutes += minutes
	_refresh_stage(false)

	if age_minutes >= definition.total_lifespan_minutes:
		_is_finished = true
		lifespan_finished.emit()


func force_refresh_stage() -> void:
	_refresh_stage(true)


func set_simulation_active(active: bool) -> void:
	_simulation_active = active


func _on_simulation_activated() -> void:
	set_simulation_active(true)


func _on_simulation_deactivated() -> void:
	set_simulation_active(false)


func _refresh_stage(force_emit: bool) -> void:
	var next_stage := definition.get_stage_for_age_minutes(age_minutes)

	if next_stage == null:
		return

	if force_emit or next_stage != current_stage:
		current_stage = next_stage
		stage_changed.emit(current_stage)


func set_age_minutes(new_age_minutes: int) -> void:
	age_minutes = max(new_age_minutes, 0)
	_is_finished = definition != null and age_minutes >= definition.total_lifespan_minutes
	_refresh_stage(true)


func reset_lifespan() -> void:
	age_minutes = 0
	_is_finished = false
	_refresh_stage(true)


func get_progress() -> float:
	if definition == null:
		return 0.0

	return clampf(
		float(age_minutes) / float(max(definition.total_lifespan_minutes, 1)),
		0.0,
		1.0
	)


func _find_simulation_entity_component() -> SimulationEntityComponent:
	var parent := get_parent()

	if parent == null:
		return null

	for child in parent.get_children():
		if child is SimulationEntityComponent:
			return child

	return null
