extends Node
class_name WorkerBlackboard

signal fact_changed(key: StringName, value: Variant)
signal target_changed(target: Node)

@export var stats: WorkerStats = WorkerStats.new()

var world_state: GOAPWorldState = GOAPWorldState.new()
var current_target: Node = null
var home_position: Vector2 = Vector2.ZERO
var desired_position: Vector2 = Vector2.ZERO
var carried_item: Node = null
var reserved_object: Node = null
var memory: Dictionary[StringName, Variant] = {}

func _ready() -> void:
	refresh_core_facts()

func _process(delta: float) -> void:
	stats.tick(delta)
	refresh_core_facts()

func refresh_core_facts() -> void:
	set_fact(&"has_item", carried_item != null)
	set_fact(&"needs_rest", stats.needs_rest())
	set_fact(&"is_exhausted", stats.is_exhausted())
	set_fact(&"has_target", current_target != null)

func set_fact(key: StringName, value: Variant) -> void:
	var old_value: Variant = world_state.get_fact(key)
	if old_value == value:
		return

	world_state.set_fact(key, value)
	fact_changed.emit(key, value)

func get_fact(key: StringName, default_value: Variant = null) -> Variant:
	return world_state.get_fact(key, default_value)

func set_target(target: Node) -> void:
	if current_target == target:
		return

	current_target = target
	target_changed.emit(current_target)
	refresh_core_facts()

func clear_target() -> void:
	set_target(null)

func get_target_position() -> Vector2:
	if current_target is Node2D:
		return (current_target as Node2D).global_position
	return desired_position

func remember(key: StringName, value: Variant) -> void:
	memory[key] = value

func recall(key: StringName, default_value: Variant = null) -> Variant:
	return memory.get(key, default_value)
