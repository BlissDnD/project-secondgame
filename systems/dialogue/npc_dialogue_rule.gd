extends Resource
class_name NPCDialogueRule

@export var rule_id: StringName
@export var priority: int = 0

@export_category("Condition")
@export var required_world_flag: StringName
@export var required_flag_value: bool = true
@export var min_interaction_count: int = -1
@export var max_interaction_count: int = -1

@export_category("Result")
@export var dialogue: DialogueScriptResource


func matches(npc_id: StringName) -> bool:
	if dialogue == null:
		return false

	var has_condition: bool = false

	if required_world_flag != &"":
		has_condition = true

		var flag_value: bool = GameStateManager.get_world_flag(required_world_flag)

		if flag_value != required_flag_value:
			return false

	if min_interaction_count >= 0:
		has_condition = true

		var interaction_count_min: int = GameStateManager.get_npc_interaction_count(npc_id)

		if interaction_count_min < min_interaction_count:
			return false

	if max_interaction_count >= 0:
		has_condition = true

		var interaction_count_max: int = GameStateManager.get_npc_interaction_count(npc_id)

		if interaction_count_max > max_interaction_count:
			return false

	if not has_condition:
		return false

	return true
