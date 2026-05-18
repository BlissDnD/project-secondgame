extends CharacterBody2D
class_name NPCController

signal interaction_started(npc: NPCController)
signal interaction_ended(npc: NPCController)

@export var npc_definition: NPCDefinition
@export var dialogue: DialogueResource
@export var idle_dialogue: IdleDialogueResource

var spawn_position: Vector2
var is_interacting: bool = false
var idle_bark_timer: float = 0.0
var interaction_cooldown_timer: float = 0.0

@onready var wander_controller: NPCWanderController = $NPCWanderController if has_node("NPCWanderController") else null


func _ready() -> void:
	spawn_position = global_position

	if npc_definition != null:
		_apply_definition(npc_definition)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	_reset_idle_bark_timer()


func _process(delta: float) -> void:
	if interaction_cooldown_timer > 0.0:
		interaction_cooldown_timer -= delta

	if idle_dialogue == null:
		return

	if is_interacting:
		return

	if DialogueManager.is_active:
		return

	if interaction_cooldown_timer > 0.0:
		return

	idle_bark_timer -= delta

	if idle_bark_timer <= 0.0:
		var bark_manager: Node = get_node_or_null("/root/BarkManager")

		if bark_manager != null and bark_manager.has_method("try_show_idle_bark"):
			bark_manager.try_show_idle_bark(idle_dialogue, get_dialogue_anchor())

		_reset_idle_bark_timer()


func get_spawn_position() -> Vector2:
	return spawn_position


func setup(definition: NPCDefinition, origin_position: Vector2) -> void:
	npc_definition = definition
	spawn_position = origin_position
	global_position = origin_position
	_apply_definition(definition)
	_reset_idle_bark_timer()


func _apply_definition(definition: NPCDefinition) -> void:
	if wander_controller == null and has_node("NPCWanderController"):
		wander_controller = $NPCWanderController

	if wander_controller != null:
		wander_controller.setup(self, definition)


func interact(_interactor: Node = null) -> void:
	print("NPC interact called on: ", name)
	start_interaction(_interactor)


func start_interaction(_interactor: Node = null) -> void:
	if is_interacting:
		print("NPC already interacting: ", name)
		return

	is_interacting = true
	velocity = Vector2.ZERO

	if wander_controller != null and dialogue != null and dialogue.pause_speaker_movement:
		wander_controller.set_paused(true)

	interaction_started.emit(self)

	print("NPC start_interaction: ", name)

	if dialogue != null:
		print("Starting dialogue: ", dialogue.dialogue_id)
		DialogueManager.start_dialogue(dialogue, get_dialogue_anchor(), _interactor as Node2D)
	else:
		push_warning("%s has no dialogue assigned." % name)
		end_interaction()


func end_interaction() -> void:
	if not is_interacting:
		return

	is_interacting = false

	if wander_controller != null:
		wander_controller.set_paused(false)

	interaction_ended.emit(self)

	if idle_dialogue != null:
		interaction_cooldown_timer = idle_dialogue.cooldown_after_interaction
		_reset_idle_bark_timer()


func get_dialogue_anchor() -> Node2D:
	if has_node("DialogueAnchor"):
		return $DialogueAnchor

	return self


func _reset_idle_bark_timer() -> void:
	if idle_dialogue == null:
		return

	idle_bark_timer = randf_range(
		idle_dialogue.min_interval,
		idle_dialogue.max_interval
	)


func _on_dialogue_ended(_ended_dialogue: DialogueResource) -> void:
	if is_interacting:
		end_interaction()
