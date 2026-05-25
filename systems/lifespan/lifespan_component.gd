class_name LifeSpanComponent
extends Node

signal stage_changed(new_stage: LifeSpanStageDefinition)
signal lifespan_finished

@export var definition: LifeSpanDefinition
@export var auto_start: bool = true
@export var age_minutes: int = 0

var current_stage: LifeSpanStageDefinition
var _is_finished: bool = false


func _ready() -> void:
	if definition == null:
		push_warning("LifeSpanComponent has no LifeSpanDefinition assigned.")
		return

	if auto_start:
		_refresh_stage(true)

	SimulationTickService.minute_simulation_tick.connect(_on_minute_tick)


func _exit_tree() -> void:
	if get_node_or_null("/root/SimulationTickService") != null:
		if SimulationTickService.minute_simulation_tick.is_connected(_on_minute_tick):
			SimulationTickService.minute_simulation_tick.disconnect(_on_minute_tick)


func _on_minute_tick(_total_minutes: int) -> void:
	if definition == null:
		return

	if _is_finished:
		return

	age_minutes += 1
	_refresh_stage(false)

	if age_minutes >= definition.total_lifespan_minutes:
		_is_finished = true
		lifespan_finished.emit()


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
func force_refresh_stage() -> void:
	_refresh_stage(true)
