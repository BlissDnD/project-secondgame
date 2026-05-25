extends Node
class_name WorkerStatsComponent

signal stamina_depleted
signal stamina_recovered
signal stats_changed

@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var max_stamina: float = 100.0
@export var max_carry_weight: float = 10.0

@export var stamina_low_threshold: float = 20.0
@export var stamina_recovered_threshold: float = 80.0

@export var stamina_move_drain_per_second: float = 4.0
@export var stamina_work_drain_per_second: float = 8.0
@export var stamina_rest_regen_per_second: float = 18.0

var health: float
var energy: float
var stamina: float
var carry_weight: float = 0.0

var is_stamina_low: bool = false


func _ready() -> void:
	health = max_health
	energy = max_energy
	stamina = max_stamina
	_emit_changed()


func drain_stamina(amount: float) -> void:
	if amount <= 0.0:
		return

	stamina = clampf(stamina - amount, 0.0, max_stamina)
	_check_stamina_state()
	_emit_changed()


func drain_stamina_for_movement(delta: float) -> void:
	var carry_multiplier := 1.0 + get_carry_ratio()
	drain_stamina(stamina_move_drain_per_second * carry_multiplier * delta)


func drain_stamina_for_work(delta: float) -> void:
	drain_stamina(stamina_work_drain_per_second * delta)


func recover_stamina(delta: float) -> void:
	stamina = clampf(stamina + stamina_rest_regen_per_second * delta, 0.0, max_stamina)
	_check_stamina_state()
	_emit_changed()


func set_carry_weight(value: float) -> void:
	carry_weight = clampf(value, 0.0, max_carry_weight)
	_emit_changed()


func add_carry_weight(value: float) -> void:
	set_carry_weight(carry_weight + value)


func clear_carry_weight() -> void:
	set_carry_weight(0.0)


func get_carry_ratio() -> float:
	if max_carry_weight <= 0.0:
		return 0.0

	return clampf(carry_weight / max_carry_weight, 0.0, 1.0)


func has_low_stamina() -> bool:
	return stamina <= stamina_low_threshold


func has_recovered_stamina() -> bool:
	return stamina >= stamina_recovered_threshold


func can_work() -> bool:
	return health > 0.0 and stamina > stamina_low_threshold


func is_alive() -> bool:
	return health > 0.0


func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	health = clampf(health - amount, 0.0, max_health)
	_emit_changed()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	health = clampf(health + amount, 0.0, max_health)
	_emit_changed()


func _check_stamina_state() -> void:
	if not is_stamina_low and stamina <= stamina_low_threshold:
		is_stamina_low = true
		stamina_depleted.emit()
	elif is_stamina_low and stamina >= stamina_recovered_threshold:
		is_stamina_low = false
		stamina_recovered.emit()


func _emit_changed() -> void:
	stats_changed.emit()
