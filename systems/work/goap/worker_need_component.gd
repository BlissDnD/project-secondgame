extends Node
class_name WorkerNeedComponent

@export var blackboard_path: NodePath

var blackboard: WorkerBlackboard

func _ready() -> void:
	blackboard = get_node_or_null(blackboard_path) as WorkerBlackboard
	if blackboard == null:
		push_error("WorkerNeedComponent missing blackboard_path.")

func _process(_delta: float) -> void:
	if blackboard == null:
		return

	blackboard.set_fact(&"needs_rest", blackboard.stats.needs_rest())
	blackboard.set_fact(&"is_exhausted", blackboard.stats.is_exhausted())
