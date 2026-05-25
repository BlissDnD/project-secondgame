extends Node
class_name WorkerStateMachine

signal state_changed(old_state: StringName, new_state: StringName, reason: String)

const IDLE: StringName = &"Idle"
const ASSIGNED: StringName = &"Assigned"
const MOVING_TO_WORK: StringName = &"MovingToWork"
const WORKING: StringName = &"Working"
const CARRYING: StringName = &"Carrying"
const DEPOSITING: StringName = &"Depositing"
const RECOVERING: StringName = &"Recovering"
const FAILED: StringName = &"Failed"

var current_state: StringName = IDLE
var previous_state: StringName = IDLE

var reason_for_interrupt: String = ""
var last_failure_reason: String = ""


func set_state(new_state: StringName, reason: String = "") -> void:
	if current_state == new_state:
		return

	var old_state := current_state
	previous_state = current_state
	current_state = new_state

	if reason != "":
		reason_for_interrupt = reason

	state_changed.emit(old_state, current_state, reason)


func fail(reason: String) -> void:
	last_failure_reason = reason
	set_state(FAILED, reason)


func recover(reason: String = "recovery_required") -> void:
	set_state(RECOVERING, reason)


func return_from_recovery(has_assignment: bool) -> void:
	reason_for_interrupt = ""

	if has_assignment:
		set_state(ASSIGNED, "recovery_complete")
	else:
		set_state(IDLE, "recovery_complete")


func is_idle() -> bool:
	return current_state == IDLE


func is_assigned() -> bool:
	return current_state == ASSIGNED


func is_recovering() -> bool:
	return current_state == RECOVERING


func is_failed() -> bool:
	return current_state == FAILED


func can_accept_assignment() -> bool:
	return current_state != FAILED


func can_execute_work() -> bool:
	return current_state != FAILED and current_state != RECOVERING


func get_debug_state() -> Dictionary:
	return {
		"current_state": str(current_state),
		"previous_state": str(previous_state),
		"reason_for_interrupt": reason_for_interrupt,
		"last_failure_reason": last_failure_reason
	}
