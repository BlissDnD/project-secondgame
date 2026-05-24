extends Resource
class_name ItemPhysicsProfile

@export_range(0.01, 10000.0, 0.01) var mass: float = 1.0
@export_range(0.0, 5.0, 0.01) var gravity_scale: float = 2.0

@export_range(0.0, 20.0, 0.01) var linear_damp: float = 1.0
@export_range(0.0, 20.0, 0.01) var angular_damp: float = 1.0

@export_range(0.0, 1.0, 0.01) var bounce: float = 0.05
@export_range(0.0, 2.0, 0.01) var friction: float = 0.8

@export var can_be_pushed: bool = true
@export var rolls_when_moving: bool = false
@export var slides_when_moving: bool = true

@export_range(0.01, 10000.0, 0.01) var pickup_mass_limit: float = 25.0
@export_range(0.01, 10000.0, 0.01) var comfortable_carry_mass: float = 8.0

@export_range(0.0, 1.0, 0.01) var throw_efficiency: float = 1.0
@export_range(0.0, 1.0, 0.01) var push_efficiency: float = 1.0


func can_be_lifted_by(lift_strength: float) -> bool:
	return mass <= lift_strength and mass <= pickup_mass_limit


func get_carry_speed_multiplier(carry_strength: float) -> float:
	if mass <= comfortable_carry_mass:
		return 1.0

	var overload: float = mass - comfortable_carry_mass
	var penalty: float = overload / maxf(carry_strength, 0.01)

	return clampf(1.0 - penalty, 0.25, 1.0)


func get_throw_multiplier(throw_strength: float) -> float:
	var strength_base: float = maxf(throw_strength, 0.01)
	var mass_factor: float = strength_base / (strength_base + mass)

	return clampf(mass_factor * throw_efficiency, 0.0, 1.0)
