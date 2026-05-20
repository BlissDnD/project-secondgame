extends Node
class_name WorkerNeedsComponent

signal needs_changed
signal became_sleepy
signal became_hungry
signal became_unhappy

@export var max_energy: float = 100.0
@export var max_happiness: float = 100.0
@export var max_hunger: float = 100.0

@export var energy: float = 100.0
@export var happiness: float = 100.0
@export var hunger: float = 100.0

@export var idle_energy_decay_per_second: float = 0.15
@export var idle_happiness_decay_per_second: float = 0.05
@export var idle_hunger_decay_per_second: float = 0.08

@export var work_energy_decay_per_second: float = 2.0
@export var work_happiness_decay_per_second: float = 0.75
@export var work_hunger_decay_per_second: float = 1.0

@export var sleep_energy_restore_per_second: float = 6.0

@export var sleepy_threshold: float = 20.0
@export var hungry_threshold: float = 20.0
@export var unhappy_threshold: float = 20.0

var is_sleepy: bool = false
var is_hungry: bool = false
var is_unhappy: bool = false


func apply_idle_decay(delta: float) -> void:
	energy = maxf(0.0, energy - idle_energy_decay_per_second * delta)
	happiness = maxf(0.0, happiness - idle_happiness_decay_per_second * delta)
	hunger = maxf(0.0, hunger - idle_hunger_decay_per_second * delta)
	_update_conditions()


func apply_work_decay(delta: float) -> void:
	energy = maxf(0.0, energy - work_energy_decay_per_second * delta)
	happiness = maxf(0.0, happiness - work_happiness_decay_per_second * delta)
	hunger = maxf(0.0, hunger - work_hunger_decay_per_second * delta)
	_update_conditions()


func apply_sleep_restore(delta: float) -> void:
	energy = minf(max_energy, energy + sleep_energy_restore_per_second * delta)
	_update_conditions()


func _update_conditions() -> void:
	var was_sleepy := is_sleepy
	var was_hungry := is_hungry
	var was_unhappy := is_unhappy

	is_sleepy = energy <= sleepy_threshold
	is_hungry = hunger <= hungry_threshold
	is_unhappy = happiness <= unhappy_threshold

	if is_sleepy and not was_sleepy:
		became_sleepy.emit()

	if is_hungry and not was_hungry:
		became_hungry.emit()

	if is_unhappy and not was_unhappy:
		became_unhappy.emit()

	needs_changed.emit()


func has_blocking_need() -> bool:
	return is_sleepy or is_hungry


func get_debug_text() -> String:
	return "E: %.0f Hpy: %.0f Food: %.0f" % [energy, happiness, hunger]
