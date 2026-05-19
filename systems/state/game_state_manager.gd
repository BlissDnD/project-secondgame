extends Node

signal game_mode_changed(previous_mode: StringName, new_mode: StringName)
signal world_flag_changed(flag_id: StringName, value: bool)
signal npc_state_changed(npc_id: StringName)
signal dialogue_seen(dialogue_id: StringName)

const MODE_EXPLORATION: StringName = &"exploration"
const MODE_DIALOGUE: StringName = &"dialogue"
const MODE_INVENTORY: StringName = &"inventory"
const MODE_CUTSCENE: StringName = &"cutscene"
const MODE_PAUSED: StringName = &"paused"

var current_game_mode: StringName = MODE_EXPLORATION

var world_flags: Dictionary = {}
var npc_states: Dictionary = {}
var seen_dialogues: Dictionary = {}


func set_game_mode(new_mode: StringName) -> void:
	if current_game_mode == new_mode:
		return

	var previous_mode: StringName = current_game_mode
	current_game_mode = new_mode

	game_mode_changed.emit(previous_mode, current_game_mode)


func is_mode(mode: StringName) -> bool:
	return current_game_mode == mode


func is_gameplay_input_allowed() -> bool:
	return current_game_mode == MODE_EXPLORATION


func set_world_flag(flag_id: StringName, value: bool = true) -> void:
	world_flags[flag_id] = value
	world_flag_changed.emit(flag_id, value)


func get_world_flag(flag_id: StringName, default_value: bool = false) -> bool:
	if not world_flags.has(flag_id):
		return default_value

	return bool(world_flags[flag_id])


func ensure_npc_state(npc_id: StringName) -> Dictionary:
	if not npc_states.has(npc_id):
		npc_states[npc_id] = {
			"interaction_count": 0,
			"has_met_player": false,
			"current_stage": &"",
			"last_dialogue_id": &""
		}

	return npc_states[npc_id]


func get_npc_state(npc_id: StringName) -> Dictionary:
	return ensure_npc_state(npc_id)


func get_npc_value(npc_id: StringName, key: StringName, default_value: Variant = null) -> Variant:
	var state: Dictionary = ensure_npc_state(npc_id)

	if not state.has(key):
		return default_value

	return state[key]


func set_npc_value(npc_id: StringName, key: StringName, value: Variant) -> void:
	var state: Dictionary = ensure_npc_state(npc_id)
	state[key] = value
	npc_state_changed.emit(npc_id)


func increment_npc_interaction_count(npc_id: StringName) -> int:
	var state: Dictionary = ensure_npc_state(npc_id)
	var count: int = int(state.get("interaction_count", 0)) + 1
	state["interaction_count"] = count
	state["has_met_player"] = true

	npc_state_changed.emit(npc_id)

	return count


func get_npc_interaction_count(npc_id: StringName) -> int:
	var state: Dictionary = ensure_npc_state(npc_id)
	return int(state.get("interaction_count", 0))


func mark_dialogue_seen(dialogue_id: StringName) -> void:
	if dialogue_id == &"":
		return

	seen_dialogues[dialogue_id] = true
	dialogue_seen.emit(dialogue_id)


func has_seen_dialogue(dialogue_id: StringName) -> bool:
	return bool(seen_dialogues.get(dialogue_id, false))


func reset_runtime_state() -> void:
	current_game_mode = MODE_EXPLORATION
