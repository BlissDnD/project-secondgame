extends Node

@export var canvas_modulate: CanvasModulate
@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var night_color: Color = Color(0.18, 0.22, 0.38, 1.0)
@export var dawn_color: Color = Color(0.95, 0.55, 0.35, 1.0)
@export var dusk_color: Color = Color(0.9, 0.45, 0.35, 1.0)


func _ready() -> void:
	if canvas_modulate == null:
		push_warning("DayNightController has no CanvasModulate assigned.")

	_update_lighting()


func _process(_delta: float) -> void:
	_update_lighting()


func _update_lighting() -> void:
	if canvas_modulate == null:
		return

	var hour := _get_hour_float()
	canvas_modulate.color = _get_color_for_hour(hour)


func _get_hour_float() -> float:
	var time_of_day_seconds := WorldTimeService.get_time_of_day_seconds()
	return time_of_day_seconds / 3600.0


func _get_color_for_hour(hour: float) -> Color:
	if hour < 5.0:
		return night_color

	if hour < 7.0:
		var t := inverse_lerp(5.0, 7.0, hour)
		return night_color.lerp(dawn_color, t)

	if hour < 9.0:
		var t := inverse_lerp(7.0, 9.0, hour)
		return dawn_color.lerp(day_color, t)

	if hour < 17.0:
		return day_color

	if hour < 19.0:
		var t := inverse_lerp(17.0, 19.0, hour)
		return day_color.lerp(dusk_color, t)

	if hour < 21.0:
		var t := inverse_lerp(19.0, 21.0, hour)
		return dusk_color.lerp(night_color, t)

	return night_color
