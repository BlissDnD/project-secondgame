extends Node

signal minute_tick(total_minutes: int)
signal hour_tick(total_hours: int)
signal day_changed(day: int)
signal time_changed(world_time_seconds: float, day: int, time_of_day_seconds: float)

const REAL_SECONDS_PER_INGAME_MINUTE := 1.0
const INGAME_MINUTES_PER_DAY := 1440
const INGAME_SECONDS_PER_DAY := INGAME_MINUTES_PER_DAY * 60

@export var start_day: int = 1
@export var start_time_of_day_minutes: int = 360
@export var time_scale: float = 1.0
@export var is_time_paused: bool = false

var world_time_seconds: float = 0.0

var _last_minute: int = -1
var _last_hour: int = -1
var _last_day: int = -1


func _ready() -> void:
	var clamped_start_minutes := clampi(
		start_time_of_day_minutes,
		0,
		INGAME_MINUTES_PER_DAY - 1
	)

	world_time_seconds = float(start_day - 1) * INGAME_MINUTES_PER_DAY * REAL_SECONDS_PER_INGAME_MINUTE
	world_time_seconds += float(clamped_start_minutes) * REAL_SECONDS_PER_INGAME_MINUTE

	_update_tick_state(true)


func _process(delta: float) -> void:
	if is_time_paused:
		return

	advance_time(delta * time_scale)


func advance_time(seconds: float) -> void:
	if seconds <= 0.0:
		return

	world_time_seconds += seconds
	_update_tick_state(false)


func get_day() -> int:
	var completed_days := int(
		floor(
			world_time_seconds /
			(INGAME_MINUTES_PER_DAY * REAL_SECONDS_PER_INGAME_MINUTE)
		)
	)

	return start_day + completed_days


func get_time_of_day_seconds() -> float:
	var current_day_real_seconds := fmod(
		world_time_seconds,
		INGAME_MINUTES_PER_DAY * REAL_SECONDS_PER_INGAME_MINUTE
	)

	var normalized := current_day_real_seconds / (
		INGAME_MINUTES_PER_DAY * REAL_SECONDS_PER_INGAME_MINUTE
	)

	return normalized * INGAME_SECONDS_PER_DAY


func get_day_progress() -> float:
	return get_time_of_day_seconds() / float(INGAME_SECONDS_PER_DAY)


func get_total_minutes() -> int:
	return int(floor(world_time_seconds / REAL_SECONDS_PER_INGAME_MINUTE))


func get_total_hours() -> int:
	return int(floor(get_total_minutes() / 60.0))


func set_time_scale(new_time_scale: float) -> void:
	time_scale = max(new_time_scale, 0.0)


func pause_time() -> void:
	is_time_paused = true


func resume_time() -> void:
	is_time_paused = false


func set_world_time_seconds(new_world_time_seconds: float) -> void:
	world_time_seconds = max(new_world_time_seconds, 0.0)
	_update_tick_state(true)


func _update_tick_state(force_emit: bool) -> void:
	var current_day := get_day()
	var current_minute := get_total_minutes()
	var current_hour := get_total_hours()
	var time_of_day := get_time_of_day_seconds()

	if force_emit or current_day != _last_day:
		_last_day = current_day
		day_changed.emit(current_day)

	if force_emit or current_hour != _last_hour:
		_last_hour = current_hour
		hour_tick.emit(current_hour)

	if force_emit or current_minute != _last_minute:
		_last_minute = current_minute
		minute_tick.emit(current_minute)

	time_changed.emit(world_time_seconds, current_day, time_of_day)
