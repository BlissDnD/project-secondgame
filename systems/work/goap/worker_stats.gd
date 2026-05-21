extends Resource
class_name WorkerStats

@export var hunger: float = 0.0
@export var energy: float = 100.0
@export var stress: float = 0.0
@export var carrying_weight: float = 0.0
@export var max_energy: float = 100.0
@export var max_carry_weight: float = 10.0

func tick(delta: float) -> void:
	hunger = clampf(hunger + delta * 0.15, 0.0, 100.0)
	energy = clampf(energy - delta * 0.05, 0.0, max_energy)
	stress = clampf(stress - delta * 0.03, 0.0, 100.0)

func needs_rest() -> bool:
	return energy <= 25.0

func is_exhausted() -> bool:
	return energy <= 5.0

func can_carry(weight: float) -> bool:
	return carrying_weight + weight <= max_carry_weight

func restore_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, max_energy)

func consume_energy(amount: float) -> void:
	energy = clampf(energy - amount, 0.0, max_energy)
