extends Label

func _process(_delta: float) -> void:
	# Pull built-in engine metrics
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var process_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 # Convert to milliseconds
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var static_mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0 # Convert to MB

	# Display text formatted cleanly
	text = "FPS: %d\nProcess (CPU): %.2f ms\nPhysics (CPU): %.2f ms\nRAM: %.2f MB" % [fps, process_time, physics_time, static_mem]
