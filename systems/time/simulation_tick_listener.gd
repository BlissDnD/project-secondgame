class_name SimulationTickListener
extends RefCounted

var callback: Callable
var interval_seconds: float
var accumulator: float = 0.0
var enabled: bool = true


func _init(
	p_callback: Callable,
	p_interval_seconds: float
) -> void:
	callback = p_callback
	interval_seconds = max(p_interval_seconds, 0.01)
