extends Node


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_time_pause"):
		_toggle_pause()

	if event.is_action_pressed("debug_time_speed_1"):
		WorldTimeService.set_time_scale(1.0)

	if event.is_action_pressed("debug_time_speed_5"):
		WorldTimeService.set_time_scale(5.0)

	if event.is_action_pressed("debug_time_speed_20"):
		WorldTimeService.set_time_scale(20.0)


func _toggle_pause() -> void:
	if WorldTimeService.is_time_paused:
		WorldTimeService.resume_time()
	else:
		WorldTimeService.pause_time()
		
