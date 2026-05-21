extends Resource
class_name GOAPWorldState

@export var facts: Dictionary[StringName, Variant] = {}

func duplicate_state() -> GOAPWorldState:
	var copy := GOAPWorldState.new()
	copy.facts = facts.duplicate(true)
	return copy

func set_fact(key: StringName, value: Variant) -> void:
	facts[key] = value

func get_fact(key: StringName, default_value: Variant = null) -> Variant:
	return facts.get(key, default_value)

func has_fact(key: StringName) -> bool:
	return facts.has(key)

func erase_fact(key: StringName) -> void:
	facts.erase(key)

func matches(required: Dictionary[StringName, Variant]) -> bool:
	for key: StringName in required.keys():
		if not facts.has(key):
			return false
		if facts[key] != required[key]:
			return false
	return true

func apply_effects(effects: Dictionary[StringName, Variant]) -> void:
	for key: StringName in effects.keys():
		facts[key] = effects[key]

func score_match(desired: Dictionary[StringName, Variant]) -> int:
	var score := 0
	for key: StringName in desired.keys():
		if facts.has(key) and facts[key] == desired[key]:
			score += 1
	return score
