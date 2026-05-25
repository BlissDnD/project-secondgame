extends Label

@export var show_real_world_seconds: bool = true
@export var show_tick_counters: bool = true

var _last_fast_tick: int = 0
var _last_normal_tick: int = 0
var _last_slow_tick: int = 0
var _last_minute_tick: int = 0
var _last_hour_tick: int = 0
var _last_day_tick: int = 0


func _ready() -> void:
	if not _has_required_services():
		text = "TimeDebugDisplay missing time services."
		push_error("TimeDebugDisplay requires WorldTimeService and SimulationTickService autoloads.")
		return

	SimulationTickService.fast_tick.connect(_on_fast_tick)
	SimulationTickService.normal_tick.connect(_on_normal_tick)
	SimulationTickService.slow_tick.connect(_on_slow_tick)
	SimulationTickService.minute_simulation_tick.connect(_on_minute_tick)
	SimulationTickService.hour_simulation_tick.connect(_on_hour_tick)
	SimulationTickService.day_simulation_tick.connect(_on_day_tick)

	_update_text()


func _process(_delta: float) -> void:
	if not _has_required_services():
		return

	_update_text()


func _update_text() -> void:
	var day := WorldTimeService.get_day()
	var time_of_day_seconds := WorldTimeService.get_time_of_day_seconds()
	var day_progress := WorldTimeService.get_day_progress()

	var clock_text := _format_clock(time_of_day_seconds)

	var lines: Array[String] = []

	lines.append("DAY: %s" % day)
	lines.append("TIME: %s" % clock_text)
	lines.append("DAY PROGRESS: %0.2f" % day_progress)
	lines.append("TIME SCALE: %0.2f" % WorldTimeService.time_scale)
	lines.append("PAUSED: %s" % str(WorldTimeService.is_time_paused))

	if show_real_world_seconds:
		lines.append("WORLD SECONDS: %0.2f" % WorldTimeService.world_time_seconds)

	if show_tick_counters:
		lines.append("--- TICKS ---")
		lines.append("FAST: %s" % _last_fast_tick)
		lines.append("NORMAL: %s" % _last_normal_tick)
		lines.append("SLOW: %s" % _last_slow_tick)
		lines.append("MINUTE: %s" % _last_minute_tick)
		lines.append("HOUR: %s" % _last_hour_tick)
		lines.append("DAY TICK: %s" % _last_day_tick)

	text = "\n".join(lines)


func _format_clock(time_of_day_seconds: float) -> String:
	var total_seconds := int(time_of_day_seconds)

	var hours := int(floor(total_seconds / 3600.0)) % 24
	var minutes := int(floor(float(total_seconds % 3600) / 60.0))

	return "%02d:%02d" % [hours, minutes]


func _on_fast_tick(tick_index: int) -> void:
	_last_fast_tick = tick_index


func _on_normal_tick(tick_index: int) -> void:
	_last_normal_tick = tick_index


func _on_slow_tick(tick_index: int) -> void:
	_last_slow_tick = tick_index


func _on_minute_tick(total_minutes: int) -> void:
	_last_minute_tick = total_minutes


func _on_hour_tick(total_hours: int) -> void:
	_last_hour_tick = total_hours


func _on_day_tick(day: int) -> void:
	_last_day_tick = day


func _has_required_services() -> bool:
	return get_node_or_null("/root/WorldTimeService") != null and get_node_or_null("/root/SimulationTickService") != null
