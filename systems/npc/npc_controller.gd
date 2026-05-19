extends CharacterBody2D
class_name NPCController

signal interaction_started(npc: NPCController)
signal interaction_ended(npc: NPCController)

@export var npc_definition: NPCDefinition

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
	var idle_dialogue := get_idle_dialogue()

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


func setup(definition: NPCDefinition, origin_position: Vector2) -> void:
	npc_definition = definition
	spawn_position = origin_position
	global_position = origin_position

	_apply_definition(definition)
	_reset_idle_bark_timer()


func get_spawn_position() -> Vector2:
	return spawn_position


func get_npc_id() -> StringName:
	if npc_definition != null and npc_definition.npc_id != &"":
		return npc_definition.npc_id

	return StringName(name.to_lower())


func get_current_dialogue() -> DialogueScriptResource:
	if npc_definition == null:
		return null

	var npc_id: StringName = get_npc_id()
	var best_rule: NPCDialogueRule = null

	for rule in npc_definition.dialogue_rules:
		if rule == null:
			continue

		if not rule.matches(npc_id):
			continue

		if best_rule == null or rule.priority > best_rule.priority:
			best_rule = rule

	if best_rule != null:
		print("NPC dialogue rule matched: ", best_rule.rule_id)
		return best_rule.dialogue

	var interaction_count: int = GameStateManager.get_npc_interaction_count(npc_id)

	if interaction_count <= 0 and npc_definition.intro_dialogue != null:
		return npc_definition.intro_dialogue

	if npc_definition.repeat_dialogue != null:
		return npc_definition.repeat_dialogue

	return npc_definition.intro_dialogue


func get_idle_dialogue() -> IdleDialogueResource:
	if npc_definition == null:
		return null

	return npc_definition.idle_dialogue_resource


func _apply_definition(definition: NPCDefinition) -> void:
	if wander_controller == null and has_node("NPCWanderController"):
		wander_controller = $NPCWanderController

	if wander_controller != null:
		wander_controller.setup(self, definition)


func interact(_interactor: Node = null) -> void:
	start_interaction(_interactor)


func start_interaction(_interactor: Node = null) -> void:
	if is_interacting:
		return

	var dialogue := get_current_dialogue()
	var npc_id := get_npc_id()

	is_interacting = true
	velocity = Vector2.ZERO

	var interaction_count: int = GameStateManager.increment_npc_interaction_count(npc_id)

	print("NPC interaction count for ", npc_id, ": ", interaction_count)

	if dialogue != null:
		GameStateManager.set_npc_value(
			npc_id,
			&"last_dialogue_id",
			dialogue.dialogue_id
		)

	if wander_controller != null and dialogue != null and dialogue.pause_speaker_movement:
		wander_controller.set_paused(true)

	interaction_started.emit(self)

	if dialogue != null:
		DialogueManager.start_dialogue(
			dialogue,
			get_dialogue_anchor(),
			_interactor as Node2D
		)
	else:
		end_interaction()


func end_interaction() -> void:
	if not is_interacting:
		return

	is_interacting = false

	if wander_controller != null:
		wander_controller.set_paused(false)

	interaction_ended.emit(self)

	var idle_dialogue := get_idle_dialogue()

	if idle_dialogue != null:
		interaction_cooldown_timer = idle_dialogue.cooldown_after_interaction
		_reset_idle_bark_timer()


func get_dialogue_anchor() -> Node2D:
	if has_node("DialogueAnchor"):
		return $DialogueAnchor

	return self


func _reset_idle_bark_timer() -> void:
	var idle_dialogue := get_idle_dialogue()

	if idle_dialogue == null:
		return

	idle_bark_timer = randf_range(
		idle_dialogue.min_interval,
		idle_dialogue.max_interval
	)


func _on_dialogue_ended(_ended_dialogue) -> void:
	if is_interacting:
		end_interaction()
