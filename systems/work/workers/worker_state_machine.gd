extends Node
class_name WorkerStateMachine

signal state_changed(old_state: StringName, new_state: StringName)

const IDLE := &"idle"
const CARRIED := &"carried"
const WORKING_CRYSTAL_NODE := &"working_crystal_node"
const CARRYING_CRYSTAL_TO_MAIN := &"carrying_crystal_to_main"
const DEPOSITING_CRYSTAL := &"depositing_crystal"
const BLOCKED_CANNOT_REACH_MAIN_CRYSTAL := &"blocked_cannot_reach_main_crystal"
const SLEEPING := &"sleeping"

@export var initial_state: StringName = IDLE

var current_state: StringName


func _ready() -> void:
	current_state = initial_state


func set_state(new_state: StringName) -> void:
	if current_state == new_state:
		return

	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


func is_state(state: StringName) -> bool:
	return current_state == state


func can_move() -> bool:
	return current_state in [
		IDLE,
		CARRYING_CRYSTAL_TO_MAIN
	]


func is_busy() -> bool:
	return current_state in [
		CARRIED,
		WORKING_CRYSTAL_NODE,
		DEPOSITING_CRYSTAL,
		SLEEPING
	]
