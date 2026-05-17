extends CharacterBody2D
class_name NPCController

signal interaction_started(npc: NPCController)
signal interaction_ended(npc: NPCController)

@export var npc_definition: NPCDefinition

var spawn_position: Vector2
var is_interacting: bool = false

@onready var wander_controller: NPCWanderController = $NPCWanderController if has_node("NPCWanderController") else null

func _ready() -> void:
	spawn_position = global_position

	if npc_definition != null:
		_apply_definition(npc_definition)
func get_spawn_position() -> Vector2:
	return spawn_position
func setup(definition: NPCDefinition, origin_position: Vector2) -> void:
	npc_definition = definition
	spawn_position = origin_position
	global_position = origin_position
	_apply_definition(definition)

func _apply_definition(definition: NPCDefinition) -> void:
	if wander_controller == null and has_node("NPCWanderController"):
		wander_controller = $NPCWanderController

	if wander_controller != null:
		wander_controller.setup(self, definition)

func start_interaction() -> void:
	is_interacting = true
	velocity = Vector2.ZERO

	if wander_controller != null:
		wander_controller.set_paused(true)

	interaction_started.emit(self)

func end_interaction() -> void:
	is_interacting = false

	if wander_controller != null:
		wander_controller.set_paused(false)

	interaction_ended.emit(self)

# Hook this into your existing InteractionComponent.
# If your interaction system calls another method name, call start_interaction() from there.
func interact(_interactor: Node = null) -> void:
	start_interaction()
