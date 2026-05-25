extends Node

signal fast_tick(tick_index: int)
signal normal_tick(tick_index: int)
signal slow_tick(tick_index: int)
signal minute_simulation_tick(total_minutes: int)
signal hour_simulation_tick(total_hours: int)
signal day_simulation_tick(day: int)

@export var fast_tick_interval_seconds: float = 0.25
@export var normal_tick_interval_seconds: float = 1.0
@export var slow_tick_interval_seconds: float = 5.0

var _fast_accumulator: float = 0.0
var _normal_accumulator: float = 0.0
var _slow_accumulator: float = 0.0

var _fast_tick_index: int = 0
var _normal_tick_index: int = 0
var _slow_tick_index: int = 0


func _ready() -> void:
	if not _has_world_time_service():
		push_error("SimulationTickService requires WorldTimeService autoload.")
		return

	WorldTimeService.minute_tick.connect(_on_world_time_minute_tick)
	WorldTimeService.hour_tick.connect(_on_world_time_hour_tick)
	WorldTimeService.day_changed.connect(_on_world_time_day_changed)


func _process(delta: float) -> void:
	if not _has_world_time_service():
		return

	if WorldTimeService.is_time_paused:
		return

	var scaled_delta := delta * WorldTimeService.time_scale

	_process_fast_tick(scaled_delta)
	_process_normal_tick(scaled_delta)
	_process_slow_tick(scaled_delta)


func _process_fast_tick(delta: float) -> void:
	_fast_accumulator += delta

	while _fast_accumulator >= fast_tick_interval_seconds:
		_fast_accumulator -= fast_tick_interval_seconds
		_fast_tick_index += 1
		fast_tick.emit(_fast_tick_index)


func _process_normal_tick(delta: float) -> void:
	_normal_accumulator += delta

	while _normal_accumulator >= normal_tick_interval_seconds:
		_normal_accumulator -= normal_tick_interval_seconds
		_normal_tick_index += 1
		normal_tick.emit(_normal_tick_index)


func _process_slow_tick(delta: float) -> void:
	_slow_accumulator += delta

	while _slow_accumulator >= slow_tick_interval_seconds:
		_slow_accumulator -= slow_tick_interval_seconds
		_slow_tick_index += 1
		slow_tick.emit(_slow_tick_index)


func _on_world_time_minute_tick(total_minutes: int) -> void:
	minute_simulation_tick.emit(total_minutes)


func _on_world_time_hour_tick(total_hours: int) -> void:
	hour_simulation_tick.emit(total_hours)


func _on_world_time_day_changed(day: int) -> void:
	day_simulation_tick.emit(day)


func _has_world_time_service() -> bool:
	return Engine.has_singleton("WorldTimeService") or get_node_or_null("/root/WorldTimeService") != null
